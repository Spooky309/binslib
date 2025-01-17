const std = @import("std");
const builtin = @import("builtin");
const glfw = @import("glfw");
const keys = @import("keys.zig");

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
    _ = glfw.glfwSetKeyCallback(wnd, key_callback);
    _ = glfw.glfwSetCursorPosCallback(wnd, cursor_pos_callback);
    _ = glfw.glfwSetMouseButtonCallback(wnd, mouse_button_callback);
}

pub fn deinit() void {
    glfw.glfwDestroyWindow(wnd);
    glfw.glfwTerminate();
}

pub fn wants_close() bool {
    return glfw.glfwWindowShouldClose(wnd) == 1;
}

pub fn pump() void {
    last_input_state = current_input_state;
    // Zero out keys_pressed and keys_released
    current_input_state = .{
        .keys_held = current_input_state.keys_held,
        .mouse_pos = current_input_state.mouse_pos,
    };
    glfw.glfwPollEvents();
}

pub fn swap_buffers() void {
    glfw.glfwSwapBuffers(wnd);
}

fn early_init_if_necessary() !void {
    if (!initd) {
        if (builtin.target.os.tag == .linux and builtin.mode == .Debug) {
            // We want to force X11 on Linux so renderdoc works.
            glfw.glfwInitHint(glfw.GLFW_PLATFORM, glfw.GLFW_PLATFORM_X11);
        }
        if (glfw.glfwInit() == 0) {
            return error.GLFWInitFailure;
        }
        initd = true;
    }
}

pub fn get_window_size() [2]i32 {
    var width: i32 = 0;
    var height: i32 = 0;
    glfw.glfwGetFramebufferSize(wnd, &width, &height);
    return .{ width, height };
}

// Mouse buttons are keys, what's a better word?
pub fn get_key_pressed(key: keys.Keys) bool {
    return current_input_state.keys_pressed[@intFromEnum(key)];
}

pub fn get_key_released(key: keys.Keys) bool {
    return current_input_state.keys_released[@intFromEnum(key)];
}

pub fn get_key_held(key: keys.Keys) bool {
    return current_input_state.keys_held[@intFromEnum(key)];
}

pub fn get_mouse_position() [2]i32 {
    return current_input_state.mouse_pos;
}

pub fn get_mouse_delta() [2]i32 {
    return .{
        current_input_state.mouse_pos.x - last_input_state.mouse_pos.x,
        current_input_state.mouse_pos.y - last_input_state.mouse_pos.y,
    };
}

fn key_state_change(ukey: usize, action: i32) void {
    if (action == glfw.GLFW_PRESS) {
        current_input_state.keys_pressed[ukey] = true;
        current_input_state.keys_held[ukey] = true;
    } else if (action == glfw.GLFW_RELEASE) {
        current_input_state.keys_released[ukey] = true;
        current_input_state.keys_held[ukey] = false;
    }
}

fn key_callback(_: ?*glfw.GLFWwindow, key: i32, _: i32, action: i32, _: i32) callconv(.C) void {
    key_state_change(@intCast(key), action);
}

fn mouse_button_callback(_: ?*glfw.GLFWwindow, btn: i32, action: i32, _: i32) callconv(.C) void {
    key_state_change(@as(usize, @intCast(btn)) + glfw.GLFW_KEY_LAST, action);
}

fn cursor_pos_callback(_: ?*glfw.GLFWwindow, x: f64, y: f64) callconv(.C) void {
    current_input_state.mouse_pos = .{ @intFromFloat(x), @intFromFloat(y) };
}

const InputState = struct {
    keys_pressed: [glfw.GLFW_KEY_LAST + 8]bool = std.mem.zeroes([glfw.GLFW_KEY_LAST + 8]bool),
    keys_held: [glfw.GLFW_KEY_LAST + 8]bool = std.mem.zeroes([glfw.GLFW_KEY_LAST + 8]bool),
    keys_released: [glfw.GLFW_KEY_LAST + 8]bool = std.mem.zeroes([glfw.GLFW_KEY_LAST + 8]bool),
    mouse_pos: [2]i32 = .{ 0, 0 },
};

var initd: bool = false;
var wnd: *glfw.GLFWwindow = undefined;
var current_input_state: InputState = .{};
var last_input_state: InputState = .{};
