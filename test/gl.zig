const std = @import("std");
const gl  = @import("../src/gfx/gl.zig");

test "string from file" {
    const contents = try stringFromFile("assets/shaders/basic.frag");
    defer std.heap.page_allocator.free(contents);
    const expected: []const u8 = 
        \\#version 330 core
        \\
        \\layout (location = 0) out vec4 frag_pos;
        \\
        \\in vec3 v_vertex_position;
        \\
        \\void main() {
        \\    frag_pos = vec4(v_vertex_position, 1.0);
        \\}
    ;
    try std.testing.expect(std.mem.eql(u8, contents, expected));
}

pub fn stringFromFile(path: []const u8) ![]const u8 {
    const file = try std.fs.cwd().openFile(
        path,
        .{}
    );
    defer file.close();

    const length = try file.getEndPos();
    const contents = try file.reader().readAllAlloc(
        std.heap.page_allocator,
        length * @sizeOf(u8)
    );
    errdefer std.heap.page_allocator.free(contents);

    return contents;
}