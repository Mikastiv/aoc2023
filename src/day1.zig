const std = @import("std");
const builtin = @import("builtin");

const input = @embedFile("input");

const lettered_numbers = [_][]const u8{
    "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
};

fn getCalibration(values: *const std.ArrayList(u8)) u32 {
    return values.items[0] * 10 + values.getLast();
}

fn getLetteredNumber(str: []const u8) ?u8 {
    for (lettered_numbers, 1..) |number, value| {
        if (std.mem.startsWith(u8, str, number)) return @intCast(value);
    }

    return null;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var digits1 = std.ArrayList(u8).init(allocator);
    var digits2 = std.ArrayList(u8).init(allocator);

    var calibration1: u32 = 0;
    var calibration2: u32 = 0;

    while (lines.next()) |line_raw| {
        const line = if (builtin.os.tag == .windows) std.mem.trim(u8, line_raw, "\r") else line_raw;

        for (0..line.len) |i| {
            switch (line[i]) {
                '0'...'9' => {
                    const digit = try std.fmt.charToDigit(line[i], 10);
                    try digits1.append(digit);
                    try digits2.append(digit);
                },
                else => if (getLetteredNumber(line[i..])) |num| {
                    try digits2.append(num);
                },
            }
        }

        calibration1 += getCalibration(&digits1);
        calibration2 += getCalibration(&digits2);

        digits1.clearRetainingCapacity();
        digits2.clearRetainingCapacity();
    }

    std.debug.print("part1: {d}\n", .{calibration1});
    std.debug.print("part2: {d}\n", .{calibration2});
}
