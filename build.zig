const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const binslib_library = b.addStaticLibrary(.{
        .name = "binslib",
        .root_source_file = b.path("binslib/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    binslib_library.linkLibC();

    const glfw_flags: []const []const u8 = switch (target.result.os.tag) {
        .linux => &.{
            "-D_GLFW_X11",
        },
        .macos => &.{
            "-D_GLFW_COCOA",
        },
        else => @panic("unsupported target (for now)"),
    };

    binslib_library.addCSourceFiles(.{
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

    binslib_library.addCSourceFiles(.{
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
                "osmesa_context.c",
            },
            else => @panic("unsupported target (for now)"),
        },
        .flags = glfw_flags,
        .root = b.path("ext/glfw/src"),
    });

    binslib_library.addCSourceFile(.{
        .file = b.path("ext/glad/glad.c"),
        .flags = &.{},
    });

    binslib_library.addCSourceFile(.{
        .file = b.path("ext/stb/stb_image.c"),
        .flags = &.{},
    });

    binslib_library.addCSourceFile(.{
        .file = b.path("ext/miniaudio/miniaudio.c"),
        .flags = &.{},
    });

    const glfw_module = b.addTranslateC(.{
        .link_libc = true,
        .optimize = optimize,
        .target = target,
        .root_source_file = b.path("ext/glfw/include/GLFW/glfw3.h"),
    });

    const glad_module = b.addTranslateC(.{
        .optimize = optimize,
        .target = target,
        .root_source_file = b.path("ext/glad/glad.h"),
    });

    const stb_image_module = b.addTranslateC(.{
        .optimize = optimize,
        .target = target,
        .root_source_file = b.path("ext/stb/stbi_with_config.h"),
    });

    const miniaudio_module = b.addTranslateC(.{
        .optimize = optimize,
        .target = target,
        .root_source_file = b.path("ext/miniaudio/ma_with_config.h"),
    });

    binslib_library.root_module.addImport("glfw", glfw_module.createModule());
    binslib_library.root_module.addImport("gl", glad_module.createModule());
    binslib_library.root_module.addImport("stbi", stb_image_module.createModule());
    binslib_library.root_module.addImport("miniaudio", miniaudio_module.createModule());

    if (target.result.os.tag == .macos) {
        binslib_library.linkFramework("Foundation");
        binslib_library.linkFramework("IOKit");
        binslib_library.linkFramework("Cocoa");
        binslib_library.linkFramework("CoreAudio");
        binslib_library.linkFramework("CoreFoundation");
        binslib_library.linkFramework("AudioToolbox");
        binslib_library.linkFramework("QuartzCore");
        binslib_library.linkFramework("OpenGL");
    }

    b.installArtifact(binslib_library);

    // put the module into the global modules list so things depending on this can get it
    //   we have to do it this way because we need to install the library itself
    //   so the lsp works properly with the c imported libraries.
    b.modules.put(b.dupe("binslib"), &binslib_library.root_module) catch @panic("can't add library to modules");

    const build_examples = b.option(bool, "build_examples", "Build the examples") orelse true;

    if (build_examples) {
        addExamples(b, target, optimize, &binslib_library.root_module) catch @panic("Error adding examples.");
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

fn addExamples(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, binslib_module: *std.Build.Module) !void {
    std.log.info("Examples will build...", .{});
    var examples_dir = try std.fs.cwd().openDir("examples", .{ .iterate = true });
    defer examples_dir.close();

    var iterator = examples_dir.iterate();

    while (try iterator.next()) |f| {
        if (f.kind != .directory) {
            continue;
        }

        std.log.info("Adding example \"{s}\"", .{f.name});
        const source_path = try std.fs.path.join(b.allocator, &.{ "examples", f.name, "main.zig" });
        defer b.allocator.free(source_path);

        const prog = b.addExecutable(.{
            .name = f.name,
            .root_source_file = b.path(source_path),
            .target = target,
            .optimize = optimize,
        });
        prog.root_module.addImport("binslib", binslib_module);
        b.installArtifact(prog);
    }
}
