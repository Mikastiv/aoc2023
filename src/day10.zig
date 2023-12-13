const std = @import("std");
const utils = @import("utils.zig");

const input = @embedFile("input");

const east = 0;
const west = 1;
const north = 2;
const south = 3;

const opposites = [4]usize{ west, east, south, north };

fn connections(pipe: u8) [4]bool {
    return switch (pipe) {
        '|' => .{ false, false, true, true },
        '-' => .{ true, true, false, false },
        'L' => .{ true, false, true, false },
        'J' => .{ false, true, true, false },
        '7' => .{ false, true, false, true },
        'F' => .{ true, false, false, true },
        else => .{ false, false, false, false },
    };
}

fn getStart(map: []const []const u8) struct { usize, usize } {
    for (map, 0..) |row, j| {
        for (row, 0..) |c, i| {
            if (c == 'S') return .{ i, j };
        }
    }

    @panic("no S in map");
}

fn directionIsNotOrigin(origin: ?usize, direction: usize) bool {
    if (origin == null) return true;
    return origin.? != direction;
}

const next_offsets = [4]struct { usize, usize }{
    .{ 1, 0 },
    .{ @bitCast(@as(isize, -1)), 0 },
    .{ 0, @bitCast(@as(isize, -1)) },
    .{ 0, 1 },
};

fn advance(map: []const []const u8, x: *usize, y: *usize, curr: [4]bool, origin: *?usize, direction: usize) bool {
    if (curr[direction] and directionIsNotOrigin(origin.*, direction)) {
        const next_x_offset, const next_y_offset = next_offsets[direction];

        const next_x = x.* +% next_x_offset;
        const next_y = y.* +% next_y_offset;

        const next = connections(map[next_y][next_x]);
        if (next[opposites[direction]]) {
            x.* +%= next_x_offset;
            y.* +%= next_y_offset;
            origin.* = opposites[direction];
            return true;
        }
    }

    return false;
}

fn tracePath(alloc: std.mem.Allocator, map: []const []const u8, start: struct { usize, usize }) ![]const []const bool {
    const path = try alloc.alloc([]bool, map.len);
    for (path) |*row| {
        row.* = try alloc.alloc(bool, map[0].len);
        @memset(row.*, false);
    }

    var origin: ?usize = null;
    var x, var y = start;
    while (true) {
        if (origin != null and x == start[0] and y == start[1]) break;
        path[y][x] = true;
        const curr = connections(map[y][x]);

        if (x > 0 and advance(map, &x, &y, curr, &origin, west)) continue;
        if (x < map[0].len - 1 and advance(map, &x, &y, curr, &origin, east)) continue;
        if (y > 0 and advance(map, &x, &y, curr, &origin, north)) continue;
        if (y < map[0].len - 1 and advance(map, &x, &y, curr, &origin, south)) continue;
    }

    return path;
}

fn removeNotPath(map: []const []u8, path: []const []const bool) void {
    for (map, 0..) |row, y| {
        for (row, 0..) |*char, x| {
            if (!path[y][x]) char.* = '.';
        }
    }
}

fn isInsideLoop(map: []const []const u8, point: struct { usize, usize }) bool {
    var x, const y = point;

    const pipe = map[y][x];
    if (pipe != '.') return false;

    x += 1;
    var intersect: usize = 0;
    while (x < map[y].len) : (x += 1) {
        switch (map[y][x]) {
            '|', '7', 'F' => intersect += 1,
            else => {},
        }
    }

    return intersect % 2 != 0;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();

    var map = std.ArrayList([]u8).init(alloc);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line_raw| {
        const line = utils.windowsTrim(line_raw);

        const row = try alloc.dupe(u8, line);
        try map.append(row);
    }

    const x, const y = getStart(map.items);

    map.items[y][x] = 'L'; // TODO: not hardcode S value

    const path = try tracePath(alloc, map.items, .{ x, y });
    removeNotPath(map.items, path);

    var part1: usize = 0;
    for (path) |row| {
        for (row) |elem| {
            if (elem) part1 += 1;
        }
    }

    var part2: usize = 0;
    for (0..map.items.len) |j| {
        for (0..map.items[0].len - 1) |i| {
            if (isInsideLoop(map.items, .{ i, j })) part2 += 1;
        }
    }

    std.debug.print("part 1: {d}\n", .{part1 / 2});
    std.debug.print("part 2: {d}\n", .{part2});
}
