const std = @import("std");
const wnd = @import("../wnd/wnd.zig");
const gl = @import("gl");
const stbi = @import("stbi");

pub const Error = error{
    GLADLoadFailed,
    ImageLoadFailed
};

pub fn init() !void {
    if (gl.gladLoadGL(wnd.get_proc_address) == 0) {
        return error.GLADLoadFailed;
    }

    var max_texture_size: gl.GLint = 0;
    var max_texture_layers: gl.GLint = 0;
    var max_3d_texture_size: gl.GLint = 0;

    gl.glGetIntegerv(gl.GL_MAX_TEXTURE_SIZE, &max_texture_size);
    gl.glGetIntegerv(gl.GL_MAX_ARRAY_TEXTURE_LAYERS, &max_texture_layers);
    gl.glGetIntegerv(gl.GL_MAX_3D_TEXTURE_SIZE, &max_3d_texture_size);

    std.debug.print("GL: Max Texture Size {}\n", .{max_texture_size});
    std.debug.print("GL: Max Texture Layers {}\n", .{max_texture_layers});
    std.debug.print("GL: Max 3D Texture Size {}\n", .{max_3d_texture_size});

    // TODO(gonzo): Maybe we could use a compressed texture for the atlas?
    gl.glGenTextures(1, &sprite_atlas_id);
    gl.glBindTexture(gl.GL_TEXTURE_2D, sprite_atlas_id);
    // NOTE(gonzo): Just using 2k texture atm for atlas
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA8, 2048, 2048, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, null);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE);
}

pub fn deinit() void {
    gl.glDeleteTextures(1, &sprite_atlas_id);
}

pub fn begin_frame() void {}

pub fn end_frame() void {
    gl.glClearColor(0.1, 0.1, 0.1, 1.0);
    gl.glClear(gl.GL_COLOR_BUFFER_BIT);
    wnd.swap_buffers();
}

const Image = struct {
    width: i32,
    height: i32,
    channels: i32,
    data: ?[*]u8
};

pub fn load_image(path: []const u8, allocator: std.mem.Allocator) !Image {
    var image: Image = .{
        .width = 0,
        .height = 0,
        .channels = 0,
        .data = null
    };

    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const file_length = try file.getEndPos();

    const buffer = try allocator.alloc(u8, file_length);
    defer allocator.free(buffer);

    // NOTE(gonzo): Should probably check if the number of bytes read == the length of the file!
    const read_count = try file.read(buffer);
    if (read_count != file_length) {
        return error.ImageLoadFailed;
    }

    image.data = stbi.stbi_load_from_memory(buffer.ptr, @intCast(buffer.len), &image.width, &image.height, &image.channels, 0);
    if (image.data == null) {
        return error.ImageLoadFailed;
    }

    return image;
}

pub fn unload_image(image: *Image) void {
    stbi.stbi_image_free(image.data);
    image.* = .{
        .width = 0,
        .height = 0,
        .channels = 0,
        .data = null
    };
}

var sprite_atlas_id: gl.GLuint = 0;