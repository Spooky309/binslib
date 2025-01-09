package snd

import "base:runtime"
import "core:log"
import "core:sync"
import ma "vendor:miniaudio"
import "vendor:stb/vorbis"

Sound_Encoding :: enum {
	OGG,
	WAV,
	MP3,
	FLAC,
}

Sound_Resource :: struct {
	frames: []f32,
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
}

deinit :: proc() {
	ma.device_stop(&device)
	ma.device_uninit(&device)
}

grab_context :: proc() {
	// required so the c callback can use our context
	//  this should be called if the logger or global allocators are changed!
	ctx = context
}

load_sound_resource_from_memory :: proc(data: []byte, encoding: Sound_Encoding) -> Sound_Resource {
	frames: rawptr
	frame_count: u64

	#partial switch encoding {
	case .OGG:
		{
			channels: i32
			sample_rate: i32
			vorbis_frames: [^]i16
			num_frames := vorbis.decode_memory(
				raw_data(data),
				i32(len(data)),
				&channels,
				&sample_rate,
				&vorbis_frames,
			)
			num_frames *= channels
			if num_frames == -1 {
				log.errorf("vorbis.decode_memory returned -1")
				panic("")
			}

			required_frames := ma.convert_frames(
				nil,
				0,
				.f32,
				2,
				48000,
				vorbis_frames,
				u64(num_frames),
				.s16,
				u32(channels),
				u32(sample_rate),
			)

			converted_frames := make([]f32, required_frames)

			ma.convert_frames(
				raw_data(converted_frames),
				required_frames,
				.f32,
				2,
				48000,
				vorbis_frames,
				u64(num_frames),
				.s16,
				u32(channels),
				u32(sample_rate),
			)

			frames = raw_data(converted_frames)
			frame_count = u64(required_frames)
		}
	case:
		{
			config := ma.decoder_config_init(.f32, 2, 48000)
			result := ma.decode_memory(raw_data(data), len(data), &config, &frame_count, &frames)
			if result != .SUCCESS {
				log.errorf("decode_memory returned %v", result)
				panic("")
			}
		}
	}

	return Sound_Resource{frames = (transmute([^]f32)frames)[0:frame_count]}
}

play :: proc(res: Sound_Resource) {
	if sync.mutex_guard(&rt.lock) {
		append(&rt.playing_sounds, Playing_Sound{frames = res.frames, current_frame = 0})
	}
}

@(private)
Playing_Sound :: struct {
	frames:        []f32,
	current_frame: u64,
}

@(private)
Snd_Runtime_Data :: struct {
	lock:           sync.Mutex,
	playing_sounds: [dynamic]Playing_Sound,
}

@(private)
device: ma.device
@(private)
ctx: runtime.Context
@(private)
rt: Snd_Runtime_Data

@(private)
data_callback :: proc "c" (device: ^ma.device, output: rawptr, input: rawptr, frame_count: u32) {
	context = ctx

	frame_count := frame_count * device.playback.channels

	if sync.mutex_guard(&rt.lock) {
		for &s, i in rt.playing_sounds {
			frames_left := u64(len(s.frames)) - s.current_frame
			num_to_copy := min(frames_left, u64(frame_count))
			copy(
				(transmute([^]f32)output)[0:num_to_copy],
				s.frames[s.current_frame:s.current_frame + num_to_copy],
			)
			s.current_frame += num_to_copy
			if s.current_frame >= u64(len(s.frames)) {
				unordered_remove(&rt.playing_sounds, i)
			}
		}
	}
}
