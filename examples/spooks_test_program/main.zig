const std = @import("std");

const core = @import("binslib").core;
const draw = @import("binslib").draw;
const snd = @import("binslib").snd;
const vfs = @import("binslib").vfs;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var temp_allocator = std.heap.ArenaAllocator.init(gpa.allocator());

    try core.init(800, 600, "binslib");
    defer core.deinit();

    try vfs.init(gpa.allocator());
    defer vfs.deinit();
    try vfs.mount_directory("res");

    // HTTP mounting expects the endpoint to have a file in the root called "reslist"
    //   that contains a list of _all_ files served, with their paths relative to the root.
    //   See the "res" folder in this example for details, although it doesn't have to be a
    //   static file, it could be served by a CGI script.

    //try vfs.mount_http(gpa.allocator(), "http://127.0.0.1:8000/");

    try snd.init(gpa.allocator());
    defer snd.deinit();

    try draw.init(gpa.allocator());
    defer draw.deinit(gpa.allocator());

    const audio_test_file = try vfs.get_file(gpa.allocator(), "sound/audio_test_vorbis");
    const audio_file = try snd.decode(gpa.allocator(), audio_test_file.data);
    var output_node = snd.Output(snd.Spatialize(snd.ResourceSource)){
        .input = .{
            .input = .{
                .res = audio_file,
            },
        },
        .loop = true,
    };
    try snd.add_output_node(&output_node);
    output_node.play();

    var t: f32 = 0;
    var last_time = std.time.milliTimestamp();

    while (!core.wants_close()) {
        core.pump();
        draw.begin_frame();
        draw.end_frame();

        const current_time = std.time.milliTimestamp();
        const delta = current_time - last_time;
        last_time = current_time;
        t += @floatFromInt(delta);

        const sintime = @sin(t / 500);
        const costime = @cos(t / 500);
        const distance = 1; // This can vary but who cares

        output_node.input.vector[0] = sintime * distance;
        output_node.input.vector[1] = costime * distance;

        // We don't care if this fails.
        _ = temp_allocator.reset(.retain_capacity);
    }
}
