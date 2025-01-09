pub const glfw = @import("glfw");

pub const Error = error{
    GLFWInitFailure,
    GLFWWindowCreationFailure,
};

pub fn init(width: u32, height: u32, name: [:0]const u8) !void {
    try early_init_if_necessary();
    wnd = glfw.glfwCreateWindow(@intCast(width), @intCast(height), name.ptr, null, null) orelse {
        return error.GLFWWindowCreationFailure;
    };
}

pub fn deinit() void {
    glfw.glfwDestroyWindow(wnd);
    glfw.glfwTerminate();
}

pub fn wants_close() bool {
    return glfw.glfwWindowShouldClose(wnd) == 1;
}

pub fn pump() void {
    glfw.glfwPollEvents();
}

fn early_init_if_necessary() !void {
    if (!initd) {
        if (glfw.glfwInit() == 0) {
            return error.GLFWInitFailure;
        }
        initd = true;
    }
}

var initd: bool = false;
var wnd: *glfw.GLFWwindow = undefined;
