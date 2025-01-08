package gl33

import "../../wnd"
import gl "vendor:OpenGL"

init :: proc() {
	gl.load_up_to(3, 3, wnd.get_opengl_proc_address)
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
