const wnd = @import("../wnd/wnd.zig");
const gl = @import("gl");

pub const Error = error{
    GLADLoadFailed,
};

pub fn init() !void {
    if (gl.gladLoadGL(wnd.get_proc_address) == 0) {
        return error.GLADLoadFailed;
    }
}

pub fn deinit() void {}

pub fn begin_frame() void {}

pub fn end_frame() void {
    gl.glClearColor(0.1, 0.1, 0.1, 1.0);
    gl.glClear(gl.GL_COLOR_BUFFER_BIT);
    wnd.swap_buffers();
}
