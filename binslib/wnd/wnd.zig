pub const glfw = @import("glfw");

pub const get_proc_address = glfw.glfwGetProcAddress;

pub const Error = error{
    GLFWInitFailure,
    GLFWWindowCreationFailure,
};

pub fn init(width: u32, height: u32, name: [:0]const u8) !void {
    try early_init_if_necessary();
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MINOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_PROFILE, glfw.GLFW_OPENGL_CORE_PROFILE);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_FORWARD_COMPAT, 1);
    wnd = glfw.glfwCreateWindow(@intCast(width), @intCast(height), name.ptr, null, null) orelse {
        return error.GLFWWindowCreationFailure;
    };
    glfw.glfwMakeContextCurrent(wnd);
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

pub fn swap_buffers() void {
    glfw.glfwSwapBuffers(wnd);
}

fn early_init_if_necessary() !void {
    if (!initd) {
        if (glfw.glfwInit() == 0) {
            return error.GLFWInitFailure;
        }
        initd = true;
    }
}

pub fn get_size() struct { i32, i32 } {
    var width: i32 = 0;
    var height: i32 = 0;
    glfw.glfwGetFramebufferSize(wnd, &width, &height);
    return .{ width, height };
}

var initd: bool = false;
var wnd: *glfw.GLFWwindow = undefined;
