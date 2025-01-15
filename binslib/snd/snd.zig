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
        fn resolve(self_erased: *anyopaque, out: []f32) void {
            const self: *@This() = @ptrCast(@alignCast(self_erased));
            if (!self.playing or @TypeOf(InputNodeType) == void) {
                return;
            }
            for (0..out.len / 2) |idx| {
                out[idx * 2], out[idx * 2 + 1] = self.input.resolve();
            }
            if (self.input.stopped()) {
                if (self.loop) {
                    self.reset();
                } else {
                    self.playing = false;
                }
            }
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

pub const NullSource = struct {
    fn resolve(_: *@This()) [2]f32 {
        return .{ 0, 0 };
    }
    fn reset(_: *@This()) void {}
    fn stopped(_: @This()) bool {
        return false;
    }
};

pub fn Spatialize(comptime InputNodeType: type) type {
    return struct {
        input: InputNodeType,
        vector: @Vector(3, f32) = .{ 0, 0, 0 },
        fn resolve(self: *@This()) [2]f32 {
            if (@TypeOf(InputNodeType) == void) {
                return .{ 0, 0 };
            }
            const samples = self.input.resolve();

            const mixdown = (samples[0] + samples[1]) / 2;
            // TODO: When gonzo merges his math library, use Vector2.magnitude (or whatever) instead.
            const distance = @sqrt(self.vector[0] * self.vector[0] + self.vector[1] * self.vector[1] + self.vector[2] * self.vector[2]);
            var mixdown_with_falloff = if (distance == 0) mixdown else mixdown / (4 * std.math.pi * distance);
            // Don't let it get any louder than the actual sample
            if (@abs(mixdown_with_falloff) > @abs(mixdown)) {
                mixdown_with_falloff = mixdown;
            }
            const radius = 1;
            const pan = std.math.clamp(self.vector[0], -radius, radius) / radius;
            const pan_right = (pan + 1) / 2;
            const pan_left = (1 - pan) / 2;

            return .{
                mixdown_with_falloff * pan_left,
                mixdown_with_falloff * pan_right,
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
    resolve_func: *const fn (self: *anyopaque, out: []f32) void,
    ptr: *anyopaque,
};

// device, out, in, frame_count
fn data_callback(_: ?*anyopaque, out: ?*anyopaque, _: ?*const anyopaque, frame_count: u32) callconv(.C) void {
    // This monstrosity converts the out pointer to a slice of f32s
    const out_floats = (@as([*c]f32, @ptrCast(@alignCast(out.?))))[0 .. frame_count * CHANNEL_COUNT];

    lock.lock();
    for (playing_sounds.items) |*item| {
        item.resolve_func(item.ptr, out_floats);
    }
    lock.unlock();
}

var device: ma.ma_device = undefined;
var playing_sounds: std.ArrayList(Graph) = undefined;
var lock = std.Thread.Mutex{};
