const std = @import("std");
const builtin = @import("builtin");

pub fn windowsTrim(str: []const u8) []const u8 {
    return if (builtin.os.tag == .windows) std.mem.trim(u8, str, "\r") else str;
}
