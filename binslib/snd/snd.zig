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

pub const SAMPLE_RATE = 44100;

pub fn init(gpa: std.mem.Allocator) !void {
    var config = ma.ma_device_config_init(ma.ma_device_type_playback);
    config.sampleRate = SAMPLE_RATE;
    config.playback.channels = 2;
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
    var config = ma.ma_decoder_config_init(ma.ma_format_f32, 2, SAMPLE_RATE);
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

pub fn play(res: Resource) !void {
    lock.lock();
    try playing_sounds.append(.{ .frames = res.frames, .current_frame = 0 });
    lock.unlock();
}

const PlayingSound = struct {
    frames: []f32,
    current_frame: usize,
};

// device, out, in, frame_count
fn data_callback(_: ?*anyopaque, out: ?*anyopaque, _: ?*const anyopaque, fake_frame_count: u32) callconv(.C) void {
    // The actual number of frames we need to copy is _per channel_
    const actual_frame_count = fake_frame_count * device.playback.channels;
    // This monstrosity converts the out pointer to a slice of f32s
    const out_floats = (@as([*c]f32, @ptrCast(@alignCast(out.?))))[0..actual_frame_count];

    lock.lock();
    for (playing_sounds.items, 0..) |*item, idx| {
        const frames_left = item.frames.len - item.current_frame;
        const num_to_copy = @min(frames_left, actual_frame_count);
        @memcpy(out_floats[0..num_to_copy], item.frames[item.current_frame..][0..num_to_copy]);
        item.current_frame += num_to_copy;
        if (item.current_frame >= item.frames.len) {
            _ = playing_sounds.swapRemove(idx);
        }
    }
    lock.unlock();
}

var device: ma.ma_device = undefined;
var playing_sounds: std.ArrayList(PlayingSound) = undefined;
var lock = std.Thread.Mutex{};
