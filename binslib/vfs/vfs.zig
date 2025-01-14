pub const std = @import("std");

pub const Error = error{
    FileNotFound,
};

pub const File = struct {
    data: []u8,
    extension: []const u8,
};

pub fn init(gpa: std.mem.Allocator) !void {
    file_map = @TypeOf(file_map).init(gpa);
}

pub fn deinit() void {}

pub fn mount_directory(gpa: std.mem.Allocator, dir: []const u8) !void {
    const exe_path = try std.fs.selfExeDirPathAlloc(gpa);
    defer gpa.free(exe_path);

    const dir_path = try std.fs.path.join(gpa, &.{ exe_path, dir });
    defer gpa.free(dir_path);

    var open_dir = try std.fs.openDirAbsolute(dir_path, .{ .iterate = true, .access_sub_paths = true });
    defer open_dir.close();
    var walker = try open_dir.walk(gpa);
    defer walker.deinit();

    while (try walker.next()) |f| {
        if (f.kind == .file) {
            const file_full_path = try std.fs.path.join(gpa, &.{ dir_path, f.path });

            const virtual_path = if (std.mem.lastIndexOf(u8, f.path, ".")) |idx|
                try gpa.dupe(u8, f.path[0..idx])
            else
                try gpa.dupe(u8, f.path);

            std.log.info("{s}", .{virtual_path});

            try file_map.put(virtual_path, .{
                .virtual_path = virtual_path,
                .extension = try gpa.dupe(u8, std.fs.path.extension(f.path)),
                .file = .{ .LooseFile = .{ .real_path = file_full_path } },
            });
        }
    }
}

pub fn mount_archive(_: []const u8) !void {
    // TODO...
    unreachable;
}

// Allocates for extension and data, owned by caller.
pub fn get_file(gpa: std.mem.Allocator, path: []const u8) !File {
    std.log.info("{s}", .{path});
    if (file_map.get(path)) |file| {
        var f: File = .{
            .data = &.{},
            .extension = try gpa.dupe(u8, file.extension),
        };

        switch (file.file) {
            .LooseFile => |loose| {
                var osf = try std.fs.openFileAbsolute(loose.real_path, .{ .mode = .read_only });
                defer osf.close();
                f.data = try osf.readToEndAlloc(gpa, std.math.maxInt(usize));
            },
            .Archive => {
                // TODO...
                unreachable;
            },
        }

        return f;
    } else {
        return error.FileNotFound;
    }
}

const VirtualFileSource = enum {
    LooseFile,
    Archive,
};

// TODO...
const ArchiveDirectory = struct {};

const Archive = struct {
    root_directory: ArchiveDirectory,
    file_handle: std.fs.File,
};

const VirtualFile = struct {
    virtual_path: []u8,
    extension: []u8,
    file: union(VirtualFileSource) {
        LooseFile: struct {
            real_path: []u8,
        },
        Archive: *Archive,
    },
};

var file_map: std.StringHashMap(VirtualFile) = undefined;
