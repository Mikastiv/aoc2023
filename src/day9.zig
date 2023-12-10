const std = @import("std");
const utils = @import("utils.zig");

const input = @embedFile("input");

fn solve(alloc: std.mem.Allocator, numbers: []i64) !struct { i64, i64 } {
    var arrays = std.ArrayList(std.ArrayList(i64)).init(alloc);
    try arrays.append(std.ArrayList(i64).fromOwnedSlice(alloc, numbers));

    var i: u64 = 0;
    while (std.mem.indexOfNone(i64, arrays.items[i].items, &[_]i64{0}) != null) : (i += 1) {
        const it = arrays.items[i];
        var next_row = try std.ArrayList(i64).initCapacity(alloc, it.items.len + 2);
        var windows = std.mem.window(i64, it.items, 2, 1);
        while (windows.next()) |window| {
            try next_row.append(window[1] - window[0]);
        }
        try arrays.append(next_row);
    }

    var last_numbers = try std.ArrayList(i64).initCapacity(alloc, arrays.items.len);
    var first_numbers = try std.ArrayList(i64).initCapacity(alloc, arrays.items.len);
    for (arrays.items) |row| {
        try first_numbers.append(row.items[0]);
        try last_numbers.append(row.getLast());
    }

    // part 1
    std.mem.reverse(i64, last_numbers.items);
    var part1: i64 = 0;
    for (last_numbers.items) |item| {
        part1 += item;
    }

    // part 2
    std.mem.reverse(i64, first_numbers.items);
    var part2: i64 = 0;
    for (first_numbers.items) |item| {
        part2 = item - part2;
    }

    return .{ part1, part2 };
}

pub fn main() !void {
    var buffer: [8192]u8 = undefined;
    var fixed = std.heap.FixedBufferAllocator.init(&buffer);
    const alloc = fixed.allocator();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var numbers = std.ArrayList(i64).init(alloc);
    var sum1: i64 = 0;
    var sum2: i64 = 0;
    while (lines.next()) |line_raw| {
        const line = utils.windowsTrim(line_raw);
        var it = std.mem.tokenizeScalar(u8, line, ' ');
        while (it.next()) |str| {
            try numbers.append(try std.fmt.parseInt(i64, str, 10));
        }

        const part1, const part2 = try solve(alloc, numbers.items);
        sum1 += part1;
        sum2 += part2;

        numbers.clearAndFree();
        fixed.reset();
    }

    std.debug.print("part 1: {d}\n", .{sum1});
    std.debug.print("part 2: {d}\n", .{sum2});
}
