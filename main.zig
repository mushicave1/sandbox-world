const std = @import("std");
const writer = std.io.getStdOut().writer();


const Player = struct {
    name: []const u8,
    age: i32
};

pub fn main() !void {
  const player = Player{.name = "mushicave1", .age = 92};
  try writer.print("player: {any}", .{player});
}
