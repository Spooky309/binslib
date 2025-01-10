const std = @import("std");

const wnd = @import("binslib").wnd;
const draw = @import("binslib").draw;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var temp_allocator = std.heap.ArenaAllocator.init(gpa.allocator());

    try wnd.init(800, 600, "binslib");
    defer wnd.deinit();
    try draw.init(gpa.allocator());
    defer draw.deinit(gpa.allocator());
    while (!wnd.wants_close()) {
        wnd.pump();
        draw.begin_frame();
        draw.end_frame();

        // We don't care if this fails.
        _ = temp_allocator.reset(.retain_capacity);
    }
}
