package main

import "../binslib/draw"
import "../binslib/snd"
import "../binslib/wnd"
import "core:log"
import "core:mem"

main :: proc() {
	context.logger = log.create_console_logger()

	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				log.errorf("=== %v allocations not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					log.errorf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				log.errorf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					log.errorf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	window_size := wnd.get_screen_size() * 0.75

	wnd.init(u32(window_size.x), u32(window_size.y), "Binslib Test Program")
	defer wnd.deinit()

	draw.init()
	defer draw.deinit()

	snd.init()
	defer snd.deinit()

	for !wnd.wants_close() {
		wnd.poll()
		draw.begin_frame()
		draw.end_frame()
	}
}
