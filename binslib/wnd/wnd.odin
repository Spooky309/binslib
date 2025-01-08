package wnd

import "core:c"
import "core:strings"
import gl "vendor:OpenGL"
import "vendor:glfw"

get_opengl_proc_address :: glfw.gl_set_proc_address

@(private)
init_if_necessary :: proc() {
	if !initd {
		glfw.Init()
		initd = true
	}
}

init :: proc(width: u32, height: u32, name: string) {
	init_if_necessary()
	cstrtitle := strings.clone_to_cstring(name, context.temp_allocator)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
	glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, glfw.TRUE)

	window = glfw.CreateWindow(c.int(width), c.int(height), cstrtitle, nil, nil)
	glfw.MakeContextCurrent(window)
}

wants_close :: proc() -> bool {
	return glfw.WindowShouldClose(window) == true
}

poll :: proc() {
	glfw.PollEvents()
}

deinit :: proc() {
	glfw.DestroyWindow(window)
	glfw.Terminate()
}

swap_buffers :: proc() {
	glfw.SwapBuffers(window)
}

get_screen_size :: proc() -> [2]f32 {
	w, h: c.int
	init_if_necessary()
	glfw.GetMonitorWorkarea(glfw.GetPrimaryMonitor(), nil, nil, &w, &h)
	return {f32(w), f32(h)}
}

@(private)
initd := false
@(private)
window: glfw.WindowHandle
