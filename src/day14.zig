const std = @import("std");
const utils = @import("utils.zig");

const input = @embedFile("input");

fn rollNorth(map: [][]u8) void {
    for (0..map[0].len) |x| {
        for (0..map.len) |_| {
            for (0..map.len - 1) |y| {
                if (map[y][x] == '.' and map[y + 1][x] == 'O')
                    std.mem.swap(u8, &map[y][x], &map[y + 1][x]);
            }
        }
    }
}

fn rollCycle(map: [][]u8) void {
    // north
    rollNorth(map);
    // west
    for (0..map.len) |y| {
        for (0..map[0].len) |_| {
            for (0..map[0].len - 1) |x| {
                if (map[y][x] == '.' and map[y][x + 1] == 'O')
                    std.mem.swap(u8, &map[y][x], &map[y][x + 1]);
            }
        }
    }
    // south
    for (0..map[0].len) |x| {
        for (0..map.len) |_| {
            var y: usize = map.len - 1;
            while (y > 0) : (y -= 1) {
                if (map[y][x] == '.' and map[y - 1][x] == 'O')
                    std.mem.swap(u8, &map[y][x], &map[y - 1][x]);
            }
        }
    }
    // east
    for (0..map.len) |y| {
        for (0..map[0].len) |_| {
            var x: usize = map[0].len - 1;
            while (x > 0) : (x -= 1) {
                if (map[y][x] == '.' and map[y][x - 1] == 'O')
                    std.mem.swap(u8, &map[y][x], &map[y][x - 1]);
            }
        }
    }
}

fn load(map: []const []const u8) u64 {
    var result: u64 = 0;
    for (map, 0..) |row, y| {
        for (row) |c| {
            if (c == 'O') result += map.len - y;
        }
    }
    return result;
}

fn mapHash(map: []const []const u8) u64 {
    var hasher = std.hash.Wyhash.init(0);
    for (map) |line| {
        hasher.update(line);
    }
    return hasher.final();
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var map = std.ArrayList([]u8).init(alloc);

    while (lines.next()) |line_raw| {
        const line = utils.windowsTrim(line_raw);
        try map.append(try alloc.dupe(u8, line));
    }

    const map_copy = try map.clone();
    for (map_copy.items) |*row| {
        row.* = try alloc.dupe(u8, row.*);
    }

    rollNorth(map_copy.items);
    const part1 = load(map_copy.items);

    var cache = std.AutoHashMap(u64, u64).init(alloc);
    var cycle_to_load = std.AutoHashMap(u64, u64).init(alloc);
    var part2: u64 = 0;
    for (0..1000000000) |i| {
        rollCycle(map.items);
        const hash = mapHash(map.items);

        if (cache.get(hash)) |cycle_idx| {
            const period = i - cycle_idx;
            const hash_last = (1000000000 - 1 - cycle_idx) % period + cycle_idx;
            part2 = cycle_to_load.get(hash_last).?;
            break;
        }

        try cache.putNoClobber(hash, i);
        try cycle_to_load.put(i, load(map.items));
    }

    std.debug.print("part 1: {d}\n", .{part1});
    std.debug.print("part 2: {d}\n", .{part2});
}
