const std = @import("std");
const utils = @import("utils.zig");

const input = @embedFile("input");

var buffer: [4096 * 2]u8 = undefined;

fn solve(alloc: std.mem.Allocator, numbers: []i64) !struct { i64, i64 } {
    var arrays = std.ArrayList(std.ArrayList(i64)).init(alloc);
    try arrays.append(std.ArrayList(i64).fromOwnedSlice(alloc, numbers));

    var i: u64 = 0;
    while (std.mem.indexOfNone(i64, arrays.items[i].items, &[_]i64{0}) != null) : (i += 1) {
        const it = arrays.items[i];
        var next_row = try std.ArrayList(i64).initCapacity(alloc, it.items.len);
        for (1..it.items.len) |j| {
            try next_row.append(it.items[j] - it.items[j - 1]);
        }
        try arrays.append(next_row);
    }

    // part 1
    i = arrays.items.len - 1;
    try arrays.items[i].append(0);
    while (i > 0) : (i -= 1) {
        const it = arrays.items[i];
        const j = it.items.len - 1;
        const curr = it.items[j];
        const prev = arrays.items[i - 1].items[j];
        try arrays.items[i - 1].append(prev + curr);
    }

    // part 2
    i = arrays.items.len - 1;
    try arrays.items[i].insert(0, 0);
    while (i > 0) : (i -= 1) {
        const it = arrays.items[i];
        const j = 0;
        const curr = it.items[j];
        const prev = arrays.items[i - 1].items[j];
        try arrays.items[i - 1].insert(0, prev - curr);
    }

    return .{ arrays.items[0].getLast(), arrays.items[0].items[0] };
}

pub fn main() !void {
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
