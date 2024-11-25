const std = @import("std");

pub fn readFile(path: []const u8) ![]const u8 {
    const file = try std.fs.cwd().openFile(
        path,
        .{}
    );
    defer file.close();

    const length = try file.getEndPos();

    const contents = try file.reader().readAllAlloc(
        std.heap.page_allocator,
        length
    );

    return contents;
}