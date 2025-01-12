const std = @import("std");

const wnd = @import("binslib").wnd;
const draw = @import("binslib").draw;
const snd = @import("binslib").snd;

const audio_test_file = @embedFile("res/audio_test_vorbis.ogg");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var temp_allocator = std.heap.ArenaAllocator.init(gpa.allocator());

    try snd.init(gpa.allocator());
    defer snd.deinit();
    try wnd.init(800, 600, "binslib");
    defer wnd.deinit();
    try draw.init(gpa.allocator());
    defer draw.deinit(gpa.allocator());

    const audio_file = try snd.decode(gpa.allocator(), audio_test_file);
    var output_node = snd.Output(snd.Gain(snd.ResourceSource)){
        .input = .{
            .input = .{
                .res = audio_file,
            },
            .gain = -10,
        },
        .loop = true,
    };
    try snd.add_output_node(&output_node);
    output_node.play();

    while (!wnd.wants_close()) {
        wnd.pump();
        draw.begin_frame();
        draw.end_frame();

        // We don't care if this fails.
        _ = temp_allocator.reset(.retain_capacity);
    }
}
