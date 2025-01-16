const std = @import("std");

const core = @import("binslib").core;
const draw = @import("binslib").draw;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var temp_allocator = std.heap.ArenaAllocator.init(gpa.allocator());

    try core.init(800, 600, "binslib");
    defer core.deinit();

    try draw.init(gpa.allocator());
    defer draw.deinit(gpa.allocator());

    var image = try draw.load_image("../../examples/gonzos_test_program/res/test.png", gpa.allocator());
    defer draw.unload_image(&image);

    const sprite = draw.load_sprite_from_image(image);

    var angle: f32 = 0;

    while (!core.wants_close()) {
        core.pump();

        draw.begin_frame();
        draw.draw_sprite(sprite, .{.x=400, .y=300}, angle * 2.0, 1.0, .{.x=0.5, .y=0.5});
        draw.draw_sprite(sprite, .{.x=400, .y=300}, angle, 0.25, .{.x=0.0, .y=0.0});
        draw.end_frame();

        angle += 1;
        if (angle >= 360) {
            angle = 0;
        }

        // We don't care if this fails.
        _ = temp_allocator.reset(.retain_capacity);
    }
}
