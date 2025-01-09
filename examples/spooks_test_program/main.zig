const std = @import("std");
const binslib = @import("binslib");

pub fn main() !void {
    try binslib.wnd.init(800, 600, "binslib");
    defer binslib.wnd.deinit();
    while (!binslib.wnd.wants_close()) {
        binslib.wnd.pump();
    }
}
