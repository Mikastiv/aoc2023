const std = @import("std");
const utils = @import("utils.zig");

const input = @embedFile("input");

const Pos = struct {
    x: usize,
    y: usize,
};

const Pair = struct {
    a: Pos,
    b: Pos,
};

fn getAxisDistance(from: usize, to: usize, empty: []const usize, empty_size: usize) usize {
    var dist: usize = 0;
    for (from..to) |x| {
        if (std.mem.indexOfScalar(usize, empty, x) != null)
            dist += empty_size
        else
            dist += 1;
    }
    return dist;
}

fn getDistance(a: Pos, b: Pos, empty_rows: []const usize, empty_cols: []const usize, empty_size: usize) usize {
    var dist: usize = 0;

    const max_x = @max(a.x, b.x);
    const min_x = @min(a.x, b.x);

    const max_y = @max(a.y, b.y);
    const min_y = @min(a.y, b.y);

    dist += getAxisDistance(min_x, max_x, empty_cols, empty_size);
    dist += getAxisDistance(min_y, max_y, empty_rows, empty_size);

    return dist;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var map = std.ArrayList([]u8).init(alloc);

    while (lines.next()) |line_raw| {
        const line = utils.windowsTrim(line_raw);

        const row = try alloc.dupe(u8, line);
        try map.append(row);
    }

    var galaxies = std.ArrayList(Pos).init(alloc);
    var empty_rows = std.ArrayList(usize).init(alloc);
    var empty_cols = std.ArrayList(usize).init(alloc);
    for (map.items, 0..) |row, y| {
        var all_empty = true;
        for (row, 0..) |item, x| {
            if (item == '#') {
                try galaxies.append(.{ .x = x, .y = y });
                all_empty = false;
            }
        }
        if (all_empty) try empty_rows.append(y);
    }
    for (0..map.items[0].len) |x| {
        var all_empty = true;
        for (0..map.items.len) |y| {
            if (map.items[y][x] != '.') {
                all_empty = false;
                break;
            }
        }
        if (all_empty) try empty_cols.append(x);
    }

    var pairs = std.ArrayList(Pair).init(alloc);
    for (galaxies.items[0 .. galaxies.items.len - 1], 1..) |galaxy_a, i| {
        for (galaxies.items[i..]) |galaxy_b| {
            try pairs.append(.{ .a = galaxy_a, .b = galaxy_b });
        }
    }

    var part1: usize = 0;
    for (pairs.items) |pair| {
        part1 += getDistance(pair.a, pair.b, empty_rows.items, empty_cols.items, 2);
    }

    var part2: usize = 0;
    for (pairs.items) |pair| {
        part2 += getDistance(pair.a, pair.b, empty_rows.items, empty_cols.items, 1000000);
    }

    std.debug.print("part1: {d}\n", .{part1});
    std.debug.print("part2: {d}\n", .{part2});
}
