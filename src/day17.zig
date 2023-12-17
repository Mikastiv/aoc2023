const std = @import("std");
const utils = @import("utils.zig");

const input = @embedFile("input");

const Pos = struct {
    x: usize,
    y: usize,

    fn advance(self: @This(), dir: Direction) ?@This() {
        return switch (dir) {
            .up => if (self.y == 0) null else .{ .x = self.x, .y = self.y - 1 },
            .down => .{ .x = self.x, .y = self.y + 1 },
            .left => if (self.x == 0) null else .{ .x = self.x - 1, .y = self.y },
            .right => .{ .x = self.x + 1, .y = self.y },
        };
    }

    fn eql(a: @This(), b: @This()) bool {
        return a.x == b.x and a.y == b.y;
    }
};

const Direction = enum {
    up,
    down,
    left,
    right,

    fn inverse(self: @This()) @This() {
        return switch (self) {
            .up => .down,
            .down => .up,
            .left => .right,
            .right => .left,
        };
    }
};

const StateCost = struct {
    pos: Pos,
    dir: Direction,
    straight: usize,
    cost: u32,

    fn lessThan(_: void, a: StateCost, b: StateCost) std.math.Order {
        return std.math.order(a.cost, b.cost);
    }
};

const State = struct {
    pos: Pos,
    dir: Direction,
    straight: usize,
};

fn successors(buffer: *std.BoundedArray(StateCost, 3), map: []const []const u8, s: StateCost, min: usize, max: usize) ![]StateCost {
    const rows = map.len;
    const cols = map[0].len;

    for (std.enums.values(Direction)) |dir| {
        // can't change direction if less than min
        if (s.straight < min and dir != s.dir) continue;
        // can't continue in same dir if reached max
        if (s.straight == max and dir == s.dir) continue;

        if (dir == s.dir.inverse()) continue;

        const next = s.pos.advance(dir);

        // check bounds
        if (next == null) continue;
        if (next.?.x >= cols or next.?.y >= rows) continue;

        const cost = s.cost + map[next.?.y][next.?.x];
        const moves = if (s.dir == dir) s.straight + 1 else 1;
        try buffer.append(.{
            .cost = cost,
            .pos = next.?,
            .dir = dir,
            .straight = moves,
        });
    }

    return buffer.slice();
}

fn dijkstra(alloc: std.mem.Allocator, map: []const []const u8, min: usize, max: usize) !?usize {
    var seen = std.AutoHashMap(State, usize).init(alloc);
    var queue = std.PriorityQueue(StateCost, void, StateCost.lessThan).init(alloc, {});
    var buffer = try std.BoundedArray(StateCost, 3).init(0);

    const goal = .{ .x = map[0].len - 1, .y = map.len - 1 };

    // add first two possible moves
    // right
    try queue.add(.{
        .cost = map[0][1],
        .pos = .{ .x = 1, .y = 0 },
        .dir = .right,
        .straight = 1,
    });
    // left
    try queue.add(.{
        .cost = map[1][0],
        .pos = .{ .x = 0, .y = 1 },
        .dir = .down,
        .straight = 1,
    });

    while (queue.removeOrNull()) |s| {
        if (Pos.eql(s.pos, goal)) {
            return s.cost;
        }

        const entry = try seen.getOrPut(.{ .dir = s.dir, .pos = s.pos, .straight = s.straight });
        if (entry.found_existing and entry.value_ptr.* <= s.cost) continue;

        entry.value_ptr.* = s.cost;

        buffer.len = 0;
        const nodes = try successors(&buffer, map, s, min, max);
        for (nodes) |node| {
            try queue.add(node);
        }
    }

    return null;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var map = std.ArrayList([]const u8).init(alloc);
    while (lines.next()) |line_raw| {
        const line = utils.windowsTrim(line_raw);
        const copy = try alloc.dupe(u8, line);
        for (copy) |*c| {
            c.* = try std.fmt.charToDigit(c.*, 10);
        }
        try map.append(copy);
    }

    const part1 = try dijkstra(alloc, map.items, 1, 3);
    const part2 = try dijkstra(alloc, map.items, 4, 10);
    std.debug.print("part 1: {d}\n", .{part1.?});
    std.debug.print("part 2: {d}\n", .{part2.?});
}
