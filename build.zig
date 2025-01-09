const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const binslib_module = b.addModule("binslib", .{
        .root_source_file = b.path("binslib/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const build_examples = b.option(bool, "build_examples", "Build the examples") orelse false;

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
