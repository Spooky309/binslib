package gl33

import "../../wnd"
import "core:log"
import gl "vendor:OpenGL"

init :: proc() {
	gl.load_up_to(3, 3, wnd.get_opengl_proc_address)
	max_texture_size: i32 = ---
	max_3d_texture_size: i32 = ---
	gl.GetIntegerv(gl.MAX_TEXTURE_SIZE, &max_texture_size)
	gl.GetIntegerv(gl.MAX_3D_TEXTURE_SIZE, &max_3d_texture_size)
	log.infof("max texture size: %v", max_texture_size)
	log.infof("max 3d texture size: %v", max_3d_texture_size)
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
