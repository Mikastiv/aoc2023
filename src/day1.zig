const std = @import("std");

const input = @embedFile("day1");

pub fn main() void {
    std.debug.print("{s}", .{input});
}
