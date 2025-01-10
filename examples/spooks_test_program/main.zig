const std = @import("std");

const wnd = @import("binslib").wnd;
const draw = @import("binslib").draw;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var temp_allocator = std.heap.ArenaAllocator.init(gpa.allocator());
    // I just threw in this reset here to shut up the "unchanged var" whinging
    _ = temp_allocator.reset(.retain_capacity);

    try wnd.init(800, 600, "binslib");
    defer wnd.deinit();
    try draw.init();
    defer draw.deinit();
    while (!wnd.wants_close()) {
        wnd.pump();
        draw.begin_frame();
        draw.end_frame();
    }
}
