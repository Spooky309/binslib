pub const std = @import("std");

pub const Error = error{
    FileNotFound,
    HTTPError,
};

pub const File = struct {
    data: []u8,
    extension: []const u8,
};

pub fn init(gpa: std.mem.Allocator) !void {
    file_map = @TypeOf(file_map).init(gpa);
}

pub fn deinit() void {}

pub fn mount_directory(dir: []const u8) !void {
    const exe_path = try std.fs.selfExeDirPathAlloc(file_map.allocator);
    defer file_map.allocator.free(exe_path);

    const dir_path = try std.fs.path.join(file_map.allocator, &.{ exe_path, dir });
    defer file_map.allocator.free(dir_path);

    var open_dir = try std.fs.openDirAbsolute(dir_path, .{ .iterate = true, .access_sub_paths = true });
    defer open_dir.close();
    var walker = try open_dir.walk(file_map.allocator);
    defer walker.deinit();

    while (try walker.next()) |f| {
        if (f.kind == .file) {
            const file_full_path = try std.fs.path.join(file_map.allocator, &.{ dir_path, f.path });

            const virtual_path = if (std.mem.lastIndexOf(u8, f.path, ".")) |idx|
                try file_map.allocator.dupe(u8, f.path[0..idx])
            else
                try file_map.allocator.dupe(u8, f.path);

            try file_map.put(virtual_path, .{
                .virtual_path = virtual_path,
                .extension = try file_map.allocator.dupe(u8, std.fs.path.extension(f.path)),
                .file = .{ .LooseFile = .{ .real_path = file_full_path } },
            });
        }
    }
}

pub fn mount_archive(_: []const u8) !void {
    // TODO...
    unreachable;
}

pub fn mount_http(gpa: std.mem.Allocator, endpoint: []const u8) !void {
    var client = std.http.Client{ .allocator = gpa };
    defer client.deinit();

    const reslist_url = try std.fs.path.join(gpa, &.{ endpoint, "reslist" });
    defer gpa.free(reslist_url);

    var response = std.ArrayList(u8).init(gpa);
    defer response.deinit();

    const fres = try client.fetch(.{
        .location = .{ .url = reslist_url },
        .response_storage = .{ .dynamic = &response },
    });
    switch (fres.status) {
        .ok => {
            var iterator = std.mem.split(u8, response.items, "\n");
            while (iterator.next()) |item| {
                const virtual_path = if (std.mem.lastIndexOf(u8, item, ".")) |idx|
                    try file_map.allocator.dupe(u8, item[0..idx])
                else
                    try file_map.allocator.dupe(u8, item);
                try file_map.put(virtual_path, .{
                    .virtual_path = virtual_path,
                    .extension = try file_map.allocator.dupe(u8, std.fs.path.extension(item)),
                    .file = .{ .HTTP = .{ .url = try std.fs.path.join(file_map.allocator, &.{ endpoint, item }) } },
                });
            }
        },
        else => {
            return error.HTTPError;
        },
    }
}

// Allocates for extension and data, owned by caller.
pub fn get_file(gpa: std.mem.Allocator, path: []const u8) !File {
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
            .HTTP => |httpf| {
                var client = std.http.Client{ .allocator = gpa };
                defer client.deinit();
                var response = std.ArrayList(u8).init(gpa);
                const fres = try client.fetch(.{
                    .location = .{ .url = httpf.url },
                    .response_storage = .{ .dynamic = &response },
                });
                if (fres.status != .ok) {
                    return error.HTTPError;
                }
                f.data = response.items;
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
    HTTP,
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
        Archive: struct {
            archive: *Archive,
            offset: u64,
            size: u64,
        },
        HTTP: struct {
            url: []u8,
        },
    },
};

var file_map: std.StringHashMap(VirtualFile) = undefined;
