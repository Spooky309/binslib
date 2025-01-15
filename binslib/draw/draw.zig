const std = @import("std");
const wnd = @import("../wnd/wnd.zig");
const gl = @import("gl");
const stbi = @import("stbi");
const stbtt = @import("stbtt"); // Also includes stb_rect_pack!
const math = @import("../math/math.zig");

const vertex_shader_code: [:0]const u8 =
\\#version 330 core
\\
\\layout(location = 0) in vec2 aPosition;
\\layout(location = 1) in vec2 aUV;
\\
\\out vec2 vUV;
\\
\\uniform mat4 uProjection;
\\
\\void main() {
\\    gl_Position = uProjection * vec4(aPosition, 0.0, 1.0);
\\    vUV = aUV;
\\}
;

const fragment_shader_code: [:0]const u8 =
\\#version 330 core
\\
\\in vec2 vUV;
\\
\\layout(location = 0) out vec4 result;
\\
\\uniform sampler2D uAtlas;
\\
\\void main() {
\\    result = texture(uAtlas, vUV);
\\}
;

pub const Error = error{
    GLADLoadFailed,
    ImageLoadFailed
};

const SpriteAtlas = struct {
    id: gl.GLuint,
    width: i32,
    height: i32
};

const Vertex = struct {
    position: math.vec2,
    uv: math.vec2
};

const SpriteBuffer = struct {
    vao: gl.GLuint,
    vbo: gl.GLuint,
    ibo: gl.GLuint,
    buffer: []Vertex,
    count: u32
};

pub fn init(allocator: std.mem.Allocator) !void {
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
    gl.glGenTextures(1, &sprite_atlas.id);
    gl.glBindTexture(gl.GL_TEXTURE_2D, sprite_atlas.id);
    // NOTE(gonzo): Just using 2k texture atm for atlas
    sprite_atlas.width = 2048;
    sprite_atlas.height = 2048;
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA8, sprite_atlas.width, sprite_atlas.height, 0, gl.GL_RGBA, gl.GL_UNSIGNED_BYTE, null);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_NEAREST);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_NEAREST);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_S, gl.GL_CLAMP_TO_EDGE);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_WRAP_T, gl.GL_CLAMP_TO_EDGE);

    sprite_buffer.buffer = try allocator.alloc(Vertex, 8192);

    gl.glGenVertexArrays(1, &sprite_buffer.vao);
    gl.glBindVertexArray(sprite_buffer.vao);

    gl.glGenBuffers(1, &sprite_buffer.vbo);
    gl.glBindBuffer(gl.GL_ARRAY_BUFFER, sprite_buffer.vbo);
    // NOTE(gonzo): Using 8192 vertices as a default size for sprite buffer
    gl.glBufferData(gl.GL_ARRAY_BUFFER, 8192 * @sizeOf(Vertex), null, gl.GL_STREAM_DRAW);

    gl.glEnableVertexAttribArray(0);
    gl.glEnableVertexAttribArray(1);

    gl.glVertexAttribPointer(0, 2, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "position")));
    gl.glVertexAttribPointer(1, 2, gl.GL_FLOAT, gl.GL_FALSE, @sizeOf(Vertex), @ptrFromInt(@offsetOf(Vertex, "uv")));

    const indices: []u16 = try allocator.alloc(u16, 12288);
    defer allocator.free(indices);

    for (0..2048) |i| {
        const start: u16 = @intCast(i * 4);
        const offset: u16 = @intCast(i * 6);
        indices[offset + 0] = start + 0;
        indices[offset + 1] = start + 1;
        indices[offset + 2] = start + 2;
        indices[offset + 3] = start + 2;
        indices[offset + 4] = start + 1;
        indices[offset + 5] = start + 3;
    }

    gl.glGenBuffers(1, &sprite_buffer.ibo);
    gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, sprite_buffer.ibo);
    gl.glBufferData(gl.GL_ELEMENT_ARRAY_BUFFER, 12288 * @sizeOf(u16), indices.ptr, gl.GL_STATIC_DRAW);

    gl.glBindVertexArray(0);

    const vertex_shader = gl.glCreateShader(gl.GL_VERTEX_SHADER);
    gl.glShaderSource(vertex_shader, 1, @ptrCast(&vertex_shader_code), null);
    gl.glCompileShader(vertex_shader);

    const fragment_shader = gl.glCreateShader(gl.GL_FRAGMENT_SHADER);
    gl.glShaderSource(fragment_shader, 1, @ptrCast(&fragment_shader_code), null);
    gl.glCompileShader(fragment_shader);

    sprite_shader = gl.glCreateProgram();
    gl.glAttachShader(sprite_shader, vertex_shader);
    gl.glAttachShader(sprite_shader, fragment_shader);
    gl.glLinkProgram(sprite_shader);

    gl.glDeleteShader(vertex_shader);
    gl.glDeleteShader(fragment_shader);

    const window_size = wnd.get_size();
    const projection = math.ortho(0, @floatFromInt(window_size[0]), @floatFromInt(window_size[1]), 0, 0, 1);

    gl.glUseProgram(sprite_shader);
    const projection_matrix_loc = gl.glGetUniformLocation(sprite_shader, "uProjection");
    gl.glUniformMatrix4fv(projection_matrix_loc, 1, gl.GL_FALSE, &projection.elements[0][0]); //TODO(gonzo): Check if getting a pointer like this is safe.
    
    //const rp_nodes: []stbtt.stbrp_node = try allocator.alloc(stbtt.stbrp_node, 2048);
    //defer allocator.free(rp_nodes);

    //var rp_context: stbtt.stbrp_context = undefined;
    //stbtt.stbrp_init_target(&rp_context, 2048, 2048, rp_nodes.ptr, @intCast(rp_nodes.len));
}

pub fn deinit(allocator: std.mem.Allocator) void {
    gl.glDeleteProgram(sprite_shader);
    allocator.free(sprite_buffer.buffer);
    gl.glDeleteVertexArrays(1, &sprite_buffer.vao);
    gl.glDeleteBuffers(1, &sprite_buffer.vbo);
    gl.glDeleteBuffers(1, &sprite_buffer.ibo);
    gl.glDeleteTextures(1, &sprite_atlas.id);
}

pub fn begin_frame() void {
    sprite_buffer.count = 0;
}

pub fn end_frame() void {
    gl.glClearColor(0.1, 0.1, 0.1, 1.0);
    gl.glClear(gl.GL_COLOR_BUFFER_BIT);

    if (sprite_buffer.count > 0) {
        gl.glBindBuffer(gl.GL_ARRAY_BUFFER, sprite_buffer.vbo);
        gl.glBufferSubData(gl.GL_ARRAY_BUFFER, 0, sprite_buffer.count * @sizeOf(Vertex), sprite_buffer.buffer.ptr);
        
        gl.glUseProgram(sprite_shader);
        gl.glBindTexture(gl.GL_TEXTURE_2D, sprite_atlas.id);

        gl.glBindVertexArray(sprite_buffer.vao);
        gl.glDrawElements(gl.GL_TRIANGLES, @intCast((sprite_buffer.count / 4) * 6), gl.GL_UNSIGNED_SHORT, null);
    }

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

const Rect = struct {
    x: f32,
    y: f32,
    width: f32,
    height: f32
};

const Sprite = struct {
    width: i32,
    height: i32,
    rect: Rect
};

pub fn load_sprite_from_image(image: Image) Sprite {
    var sprite: Sprite = undefined;

    sprite.width = image.width;
    sprite.height = image.height;

    const format: gl.GLenum = switch (image.channels) {
        1 => gl.GL_RED,
        2 => gl.GL_RG,
        3 => gl.GL_RGB,
        4 => gl.GL_RGBA,
        else => 0 // TODO(gonzo): Return an error here!
    };

    // NOTE(gonzo): We need to set this because otherwise the data is loaded into the texture wrong
    gl.glPixelStorei(gl.GL_UNPACK_ALIGNMENT, 1);

    gl.glBindTexture(gl.GL_TEXTURE_2D, sprite_atlas.id);
    gl.glTexSubImage2D(gl.GL_TEXTURE_2D, 0, 0, 0, image.width, image.height, format, gl.GL_UNSIGNED_BYTE, image.data);

    gl.glPixelStorei(gl.GL_UNPACK_ALIGNMENT, 4);

    sprite.rect = .{
        .x = 0.0,
        .y = 0.0,
        .width = @as(f32, @floatFromInt(image.width)) / @as(f32, @floatFromInt(sprite_atlas.width)),
        .height = @as(f32, @floatFromInt(image.height)) / @as(f32, @floatFromInt(sprite_atlas.height))
    };

    return sprite;
}

pub fn draw_sprite(sprite: Sprite, position: math.vec2, angle: f32, scale: f32, origin: math.vec2) void {
    const scaled_width: f32 = @as(f32, @floatFromInt(sprite.width)) * scale;
    const scaled_height: f32 = @as(f32, @floatFromInt(sprite.height)) * scale;

    var top_left: math.vec2 = .{ .x=-(scaled_width * origin.x), .y=-(scaled_height * origin.y) };
    var bottom_right: math.vec2 = .{ .x=scaled_width * (1.0 - origin.x), .y=scaled_height * (1.0 - origin.y) };
    var bottom_left: math.vec2 = .{ .x=top_left.x, .y=bottom_right.y };
    var top_right: math.vec2 = .{ .x=bottom_right.x, .y=top_left.y };

    if (angle != 0.0) {
        const rot_sin: f32 = @sin(std.math.degreesToRadians(angle));
        const rot_cos: f32 = @cos(std.math.degreesToRadians(angle));

        var point: math.vec2 = top_left;
        top_left = .{ .x=point.x * rot_cos - point.y * rot_sin, .y=point.x * rot_sin + point.y * rot_cos };
        
        point = bottom_right;
        bottom_right = .{ .x=point.x * rot_cos - point.y * rot_sin, .y=point.x * rot_sin + point.y * rot_cos };

        point = bottom_left;
        bottom_left = .{ .x=point.x * rot_cos - point.y * rot_sin, .y=point.x * rot_sin + point.y * rot_cos };

        point = top_right;
        top_right = .{ .x=point.x * rot_cos - point.y * rot_sin, .y=point.x * rot_sin + point.y * rot_cos };
    }

    top_left = top_left.add(position);
    bottom_right = bottom_right.add(position);
    bottom_left = bottom_left.add(position);
    top_right = top_right.add(position);

    sprite_buffer.buffer[sprite_buffer.count + 0] = .{
        .position = bottom_left,
        .uv = .{.x=sprite.rect.x, .y=sprite.rect.y}
    };

    sprite_buffer.buffer[sprite_buffer.count + 1] = .{
        .position = bottom_right,
        .uv = .{.x=sprite.rect.width, .y=sprite.rect.y}
    };

    sprite_buffer.buffer[sprite_buffer.count + 2] = .{
        .position = top_left,
        .uv = .{.x=sprite.rect.x, .y=sprite.rect.height}
    };

    sprite_buffer.buffer[sprite_buffer.count + 3] = .{
        .position = top_right,
        .uv = .{.x=sprite.rect.width, .y=sprite.rect.height}
    };

    sprite_buffer.count += 4;
}

var sprite_atlas: SpriteAtlas = undefined;
var sprite_buffer: SpriteBuffer = undefined;
var sprite_shader: gl.GLuint = 0;