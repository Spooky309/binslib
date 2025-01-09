package snd

import "base:runtime"
import "core:log"
import ma "vendor:miniaudio"

data_callback :: proc "c" (device: ^ma.device, output: rawptr, input: rawptr, frame_count: u32) {
	context = ctx
	// beware: this is called from another thread
}

init :: proc() {
	grab_context()

	config := ma.device_config_init(.playback)

	config.playback.format = .f32
	config.playback.channels = 2
	config.sampleRate = 48000

	config.dataCallback = data_callback
	if ma.device_init(nil, &config, &device) != .SUCCESS {
		panic("snd failed to initialize")
	}
	ma.device_start(&device)

	log.infof("audio frame count: %v", device.playback.internalPeriodSizeInFrames)
}

grab_context :: proc() {
	// required so the c callback can use our context
	//  this should be called if the logger or global allocators are changed!
	ctx = context
}

deinit :: proc() {
	ma.device_stop(&device)
	ma.device_uninit(&device)
}

@(private)
device: ma.device
@(private)
ctx: runtime.Context
