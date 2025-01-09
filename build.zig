const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const binslib_module = b.addModule("binslib", .{
        .root_source_file = b.path("binslib/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const glfw_flags: []const []const u8 = switch (target.result.os.tag) {
        .linux => &.{
            "-D_GLFW_X11",
        },
        .macos => &.{
            "-D_GLFW_COCOA",
        },
        else => @panic("unsupported target (for now)"),
    };

    binslib_module.addCSourceFiles(.{
        .files = &.{
            "context.c",
            "init.c",
            "input.c",
            "monitor.c",
            "platform.c",
            "vulkan.c",
            "window.c",
            "null_init.c",
            "null_joystick.c",
            "null_monitor.c",
            "null_window.c",
        },
        .flags = glfw_flags,
        .root = b.path("ext/glfw/src"),
    });
    binslib_module.link_libc = true;

    binslib_module.addCSourceFiles(.{
        .files = switch (target.result.os.tag) {
            .linux => &.{
                "egl_context.c",
                "glx_context.c",
                "linux_joystick.c",
                "osmesa_context.c",
                "posix_module.c",
                "posix_poll.c",
                "posix_thread.c",
                "posix_time.c",
                "x11_init.c",
                "x11_monitor.c",
                "x11_window.c",
                "xkb_unicode.c",
            },
            .macos => &.{
                "posix_module.c",
                "posix_poll.c",
                "posix_thread.c",
                "posix_time.c",
                "cocoa_init.m",
                "cocoa_joystick.m",
                "cocoa_monitor.m",
                "cocoa_time.c",
                "cocoa_window.m",
                "nsgl_context.m",
                "egl_context.c",
            },
            else => @panic("unsupported target (for now)"),
        },
        .flags = glfw_flags,
        .root = b.path("ext/glfw/src"),
    });

    const glfw_module = b.addTranslateC(.{
        .link_libc = true,
        .optimize = optimize,
        .target = target,
        .root_source_file = b.path("ext/glfw/include/GLFW/glfw3.h"),
    });

    binslib_module.addImport("glfw", glfw_module.createModule());

    if (target.result.os.tag == .macos) {
        binslib_module.linkFramework("Foundation", .{ .needed = true });
        binslib_module.linkFramework("Cocoa", .{ .needed = true });
    }

    const build_examples = b.option(bool, "build_examples", "Build the examples") orelse true;

    if (build_examples) {
        const spooks_test_program = b.addExecutable(.{
            .name = "spooks_test_program",
            .root_source_file = b.path("examples/spooks_test_program/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        spooks_test_program.root_module.addImport("binslib", binslib_module);

        b.installArtifact(spooks_test_program);
    }

    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("binslib/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
