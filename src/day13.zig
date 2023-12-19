const std = @import("std");

const input = @embedFile("input");

fn transpose(alloc: std.mem.Allocator, pattern: []const u64, row_len: u64) ![]const u64 {
    var t = try alloc.alloc(u64, row_len);

    var x: usize = 0;
    while (x < row_len) : (x += 1) {
        var y: usize = 0;
        t[x] = 0;
        while (y < pattern.len) : (y += 1) {
            const bit: u64 = row_len - x - 1;
            const v = (pattern[y] >> @truncate(bit)) & 1;
            t[x] <<= 1;
            t[x] |= v;
        }
    }

    return t;
}

fn reflections(pattern: []const u64) struct { u64, u64 } {
    var part1: u64 = 0;
    var part2: u64 = 0;
    for (0..pattern.len - 1) |y| {
        var diff_count: u64 = 0;
        var line_a = y;
        var line_b = y + 1;
        while (true) {
            diff_count += @popCount(pattern[line_a] ^ pattern[line_b]);
            if (line_a == 0 or line_b == pattern.len - 1) break;
            line_a -= 1;
            line_b += 1;
        }

        if (diff_count == 0) part1 += y + 1;
        if (diff_count == 1) part2 += y + 1;
    }

    return .{ part1, part2 };
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();

    var patterns = std.ArrayList([]const u64).init(alloc);
    var patterns_t = std.ArrayList([]const u64).init(alloc);
    var patterns_it = std.mem.tokenizeSequence(u8, input, "\n\n");
    while (patterns_it.next()) |pattern| {
        var lines = std.mem.tokenizeScalar(u8, pattern, '\n');
        var current_pattern = std.ArrayList(u64).init(alloc);
        var len: usize = 0;
        while (lines.next()) |line| {
            var row: usize = 0;
            for (line) |c| {
                row <<= 1;
                row |= if (c == '.') 0 else 1;
            }
            try current_pattern.append(row);
            len = line.len;
        }

        const t = try transpose(alloc, current_pattern.items, len);
        try patterns_t.append(t);
        try patterns.append(try current_pattern.toOwnedSlice());
    }

    var part1: u64 = 0;
    var part2: u64 = 0;
    for (0..patterns.items.len) |i| {
        var p1, var p2 = reflections(patterns.items[i]);
        part1 += p1 * 100;
        part2 += p2 * 100;

        p1, p2 = reflections(patterns_t.items[i]);
        part1 += p1;
        part2 += p2;
    }

    std.debug.print("part 1: {d}\n", .{part1});
    std.debug.print("part 2: {d}\n", .{part2});
}
