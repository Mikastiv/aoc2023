const std = @import("std");
const utils = @import("utils.zig");

const input = @embedFile("input");

const Pipe = [4]bool;

fn pipeConnect(pipe: u8) [4]bool {
    return switch (pipe) {
        '|' => .{ false, false, true, true },
        '-' => .{ true, true, false, false },
        'L' => .{ true, false, true, false },
        'J' => .{ false, true, true, false },
        '7' => .{ false, true, false, true },
        'F' => .{ true, false, false, true },
        '.' => .{ false, false, false, false },
        'S' => .{ true, true, true, true },
        else => unreachable,
    };
}

const Direction = enum(u32) {
    east = 0,
    west = 1,
    north = 2,
    south = 3,
};

const lookup = [_][2]i8{
    .{ -1, 0 },
    .{ 1, 0 },
    .{ 0, 1 },
    .{ 0, -1 },
};

fn solveDirectionRecursive(map: []const []const u8, x: u32, y: u32, max: u32, origin: Direction) u32 {
    const step_x, const step_y = lookup[@intFromEnum(origin)];
    const next_x: u32 = @intCast(@as(i32, @intCast(x)) + step_x);
    const next_y: u32 = @intCast(@as(i32, @intCast(y)) + step_y);

    const next = map[next_y][next_x];
    const next_connections = pipeConnect(next);
    if (next_connections[@intFromEnum(origin)])
        return 1 + solveRecursive(map, next_x, next_y, origin)
    else
        return max;
}

fn solveRecursive(map: []const []const u8, x: u32, y: u32, origin: Direction) u32 {
    const pipe = map[y][x];
    if (pipe == 'S') return 0;

    var max: u32 = 0;
    const connections = pipeConnect(pipe);

    if (x > 0 and origin != .west and connections[@intFromEnum(Direction.west)]) {
        max = @max(max, solveDirectionRecursive(map, x, y, max, .east));
    }
    if (x < map[0].len - 1 and origin != .east and connections[@intFromEnum(Direction.east)]) {
        max = @max(max, solveDirectionRecursive(map, x, y, max, .west));
    }
    if (y > 0 and origin != .north and connections[@intFromEnum(Direction.north)]) {
        max = @max(max, solveDirectionRecursive(map, x, y, max, .south));
    }
    if (y < map.len - 1 and origin != .south and connections[@intFromEnum(Direction.south)]) {
        max = @max(max, solveDirectionRecursive(map, x, y, max, .north));
    }

    return max;
}

fn solve(map: []const []const u8, x: u32, y: u32) u32 {
    var max: u32 = 0;
    if (x > 0) {
        max = @max(max, solveRecursive(map, x - 1, y, .east));
    }
    if (x < map[0].len - 1) {
        max = @max(max, solveRecursive(map, x + 1, y, .west));
    }
    if (y > 0) {
        max = @max(max, solveRecursive(map, x, y - 1, .south));
    }
    if (y < map.len - 1) {
        max = @max(max, solveRecursive(map, x, y + 1, .north));
    }

    return max / 2 + 1;
}

fn findStart(map: []const []const u8) ?struct { u32, u32 } {
    for (map, 0..) |line, y| {
        for (line, 0..) |char, x| {
            if (char == 'S') return .{ @intCast(x), @intCast(y) };
        }
    }
    return null;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();

    var map = std.ArrayList([]const u8).init(alloc);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line_raw| {
        const line = utils.windowsTrim(line_raw);

        const row = try alloc.dupe(u8, line);
        try map.append(row);
    }

    const x, const y = findStart(map.items).?;

    const result = solve(map.items, x, y);

    std.debug.print("part 1: {d}\n", .{result});
}
