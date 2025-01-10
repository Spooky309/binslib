const ma = @import("miniaudio");

pub const Error = error{
    MiniAudioDeviceCreationFailed,
};

pub fn init() !void {
    var config = ma.ma_device_config_init(ma.ma_device_type_playback);
    config.sampleRate = 44000;
    config.playback.channels = 2;
    config.playback.format = ma.ma_format_f32;
    config.dataCallback = data_callback;
    if (ma.ma_device_init(null, &config, &device) != ma.MA_SUCCESS) {
        return error.MiniAudioDeviceCreationFailed;
    }
}

pub fn deinit() void {}

// device, out, in, frame_count
fn data_callback(_: ?*anyopaque, out: ?*anyopaque, _: ?*const anyopaque, frame_count: u32) callconv(.C) void {
    // This monstrosity converts the out pointer to a slice of f32s
    var out_floats = (@as([*c]f32, @ptrCast(@alignCast(out.?))))[0..frame_count];
    out_floats[0] = 0;
}

var device: ma.ma_device = undefined;
