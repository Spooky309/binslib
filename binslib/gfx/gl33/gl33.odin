package gl33

import "../../wnd"
import "core:fmt"
import gl "vendor:OpenGL"

init :: proc() {
	gl.load_up_to(3, 3, wnd.get_opengl_proc_address)
	max_texture_size: i32 = ---
	max_3d_texture_size: i32 = ---
	max_texture_buffer_size: i32 = ---
	gl.GetIntegerv(gl.MAX_TEXTURE_SIZE, &max_texture_size)
	gl.GetIntegerv(gl.MAX_3D_TEXTURE_SIZE, &max_3d_texture_size)
	gl.GetIntegerv(gl.MAX_TEXTURE_BUFFER_SIZE, &max_texture_buffer_size)
	fmt.printf(
		"max texture size: %v\nmax 3d texture size: %v\nmax texture buffer size: %v\n",
		max_texture_size,
		max_3d_texture_size,
		max_texture_buffer_size,
	)
}

deinit :: proc() {

}

begin_frame :: proc() {

}

end_frame :: proc() {
	gl.ClearColor(0.1, 0.1, 0.1, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
	wnd.swap_buffers()
}
