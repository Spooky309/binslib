const std = @import("std");
const ma = @import("miniaudio");

pub const Error = error{
    MiniAudioDeviceCreationFailed,
    MinAudioDeviceStartFailed,
    MiniAudioDecodeFailed,
};

pub const Resource = struct {
    frames: []f32,
};

pub fn Output(comptime InputNodeType: type) type {
    return struct {
        input: InputNodeType,
        playing: bool = false,
        loop: bool = false,
        fn resolve(self_erased: *anyopaque) [2]f32 {
            const self: *@This() = @ptrCast(@alignCast(self_erased));
            if (!self.playing or @TypeOf(InputNodeType) == void) {
                return .{ 0, 0 };
            }
            const samples = self.input.resolve();
            if (self.input.stopped()) {
                if (self.loop) {
                    self.reset();
                } else {
                    self.playing = false;
                }
            }
            return samples;
        }
        pub fn play(self: *@This()) void {
            self.playing = true;
        }
        pub fn reset(self: *@This()) void {
            self.input.reset();
        }
        pub fn stopped(self: @This()) bool {
            return !self.playing;
        }
    };
}

pub const ResourceSource = struct {
    res: Resource,
    current_frame: usize = 0,
    fn resolve(self: *@This()) [2]f32 {
        if (self.current_frame >= self.res.frames.len) {
            return .{ 0, 0 };
        }
        const samples: [2]f32 = .{
            self.res.frames[self.current_frame],
            self.res.frames[self.current_frame + 1],
        };
        _ = @atomicRmw(usize, &self.current_frame, .Add, 2, .seq_cst);
        return samples;
    }
    fn reset(self: *@This()) void {
        @atomicStore(usize, &self.current_frame, 0, .seq_cst);
    }
    fn stopped(self: @This()) bool {
        return self.current_frame >= self.res.frames.len;
    }
};

pub fn Gain(comptime InputNodeType: type) type {
    return struct {
        input: InputNodeType,
        gain: f32,

        fn resolve(self: *@This()) [2]f32 {
            if (@TypeOf(InputNodeType) == void) {
                return .{ 0, 0 };
            }
            const samples = self.input.resolve();
            const coef = std.math.pow(f32, 10, self.gain / 20);
            return .{
                samples[0] * coef,
                samples[1] * coef,
            };
        }
        fn reset(self: *@This()) void {
            self.input.reset();
        }
        fn stopped(self: @This()) bool {
            return self.input.stopped();
        }
    };
}

pub const SAMPLE_RATE = 44100;
pub const CHANNEL_COUNT = 2;

pub fn init(gpa: std.mem.Allocator) !void {
    var config = ma.ma_device_config_init(ma.ma_device_type_playback);
    config.sampleRate = SAMPLE_RATE;
    config.playback.channels = CHANNEL_COUNT;
    config.playback.format = ma.ma_format_f32;
    config.dataCallback = data_callback;
    if (ma.ma_device_init(null, &config, &device) != ma.MA_SUCCESS) {
        return error.MiniAudioDeviceCreationFailed;
    }
    playing_sounds = @TypeOf(playing_sounds).init(gpa);
    if (ma.ma_device_start(&device) != ma.MA_SUCCESS) {
        return error.MiniAudioDeviceStartFailed;
    }
}

pub fn deinit() void {}

pub fn decode(gpa: std.mem.Allocator, data: []const u8) !Resource {
    var frame_count: u64 = 0;
    var config = ma.ma_decoder_config_init(ma.ma_format_f32, CHANNEL_COUNT, SAMPLE_RATE);
    var frames: ?*anyopaque = null;
    if (ma.ma_decode_memory(data.ptr, data.len, &config, &frame_count, &frames) != ma.MA_SUCCESS) {
        return error.MiniAudioDecodeFailed;
    }
    const frames_sliced = @as([*c]f32, @ptrCast(@alignCast(frames.?)))[0 .. frame_count * config.channels];
    const frames_copied = try gpa.dupe(f32, frames_sliced);

    ma.ma_free(frames, null);

    return Resource{
        .frames = frames_copied,
    };
}

pub fn add_output_node(node: anytype) !void {
    lock.lock();
    try playing_sounds.append(.{
        .resolve_func = &@TypeOf(node.*).resolve,
        .ptr = @as(*anyopaque, node),
    });
    lock.unlock();
}

const Graph = struct {
    resolve_func: *const fn (self: *anyopaque) [2]f32,
    ptr: *anyopaque,
};

// device, out, in, frame_count
fn data_callback(_: ?*anyopaque, out: ?*anyopaque, _: ?*const anyopaque, frame_count: u32) callconv(.C) void {
    // This monstrosity converts the out pointer to a slice of f32s
    const out_floats = (@as([*c]f32, @ptrCast(@alignCast(out.?))))[0 .. frame_count * CHANNEL_COUNT];

    lock.lock();
    for (playing_sounds.items) |*item| {
        for (0..frame_count) |sample| {
            out_floats[sample * CHANNEL_COUNT], out_floats[sample * CHANNEL_COUNT + 1] = item.resolve_func(item.ptr);
        }
    }
    lock.unlock();
}

var device: ma.ma_device = undefined;
var playing_sounds: std.ArrayList(Graph) = undefined;
var lock = std.Thread.Mutex{};
