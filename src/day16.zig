const std = @import("std");
const utils = @import("utils.zig");

const input = @embedFile("input");

const Direction = enum(u8) { up = 1, down = 2, left = 4, right = 8 };

fn splitBeam(source: Direction, mirror: u8) struct { ?Direction, ?Direction } {
    return switch (mirror) {
        '.' => .{ source, null },
        '/' => switch (source) {
            .up => .{ .right, null },
            .down => .{ .left, null },
            .right => .{ .up, null },
            .left => .{ .down, null },
        },
        '\\' => switch (source) {
            .up => .{ .left, null },
            .down => .{ .right, null },
            .right => .{ .down, null },
            .left => .{ .up, null },
        },
        '|' => switch (source) {
            .up, .down => .{ source, null },
            .right, .left => .{ .down, .up },
        },
        '-' => switch (source) {
            .right, .left => .{ source, null },
            .up, .down => .{ .left, .right },
        },
        else => unreachable,
    };
}

fn nextTile(dir: ?Direction, x: usize, y: usize, max_x: usize, max_y: usize) ?struct { usize, usize } {
    if (dir == null) return null;
    switch (dir.?) {
        .up => return if (y == 0) null else .{ x, y - 1 },
        .left => return if (x == 0) null else .{ x - 1, y },
        .down => return if (y == max_y) null else .{ x, y + 1 },
        .right => return if (x == max_x) null else .{ x + 1, y },
    }
}

fn shootBeam(map: []const []const u8, seen: [][]u8, dir: Direction, x: usize, y: usize) void {
    if (seen[y][x] & @intFromEnum(dir) != 0) return;

    seen[y][x] |= @intFromEnum(dir);

    const next_dir1, const next_dir2 = splitBeam(dir, map[y][x]);
    const next_1 = nextTile(next_dir1, x, y, map[0].len - 1, map.len - 1);
    const next_2 = nextTile(next_dir2, x, y, map[0].len - 1, map.len - 1);
    if (next_1) |next| {
        shootBeam(map, seen, next_dir1.?, next[0], next[1]);
    }
    if (next_2) |next| {
        shootBeam(map, seen, next_dir2.?, next[0], next[1]);
    }
}

fn countEnergizedTiles(seen: []const []const u8) usize {
    var count: usize = 0;
    for (seen) |row| {
        for (row) |value| {
            if (value != 0) count += 1;
        }
    }
    return count;
}

fn resetSeen(seen: [][]u8) void {
    for (seen) |*row| {
        @memset(row.*, 0);
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var map = std.ArrayList([]const u8).init(alloc);
    while (lines.next()) |line_raw| {
        const line = utils.windowsTrim(line_raw);
        try map.append(try alloc.dupe(u8, line));
    }

    var seen = std.ArrayList([]u8).init(alloc);
    for (map.items) |_| {
        const line = try alloc.alloc(u8, map.items[0].len);
        @memset(line, 0);
        try seen.append(line);
    }

    shootBeam(map.items, seen.items, .right, 0, 0);

    const part1 = countEnergizedTiles(seen.items);

    var part2: usize = 0;
    for (0..map.items.len) |y| {
        resetSeen(seen.items);
        shootBeam(map.items, seen.items, .right, 0, y);
        part2 = @max(part2, countEnergizedTiles(seen.items));
        resetSeen(seen.items);
        shootBeam(map.items, seen.items, .left, map.items[0].len - 1, y);
        part2 = @max(part2, countEnergizedTiles(seen.items));
    }
    for (0..map.items[0].len) |x| {
        resetSeen(seen.items);
        shootBeam(map.items, seen.items, .down, x, 0);
        part2 = @max(part2, countEnergizedTiles(seen.items));
        resetSeen(seen.items);
        shootBeam(map.items, seen.items, .up, x, map.items.len - 1);
        part2 = @max(part2, countEnergizedTiles(seen.items));
    }

    std.debug.print("part 1: {d}\n", .{part1});
    std.debug.print("part 2: {d}\n", .{part2});
}
