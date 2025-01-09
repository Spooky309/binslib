const std = @import("std");

const wnd = @import("binslib").wnd;
const draw = @import("binslib").draw;

pub fn main() !void {
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
