const std = @import("std");

const input = @embedFile("input");

const Pos = struct {
    x: i64,
    y: i64,
};

const Dir = enum { up, down, left, right };

const Op = struct {
    dir: Dir,
    count: i64,

    fn fromStrPart1(str: []const u8) !@This() {
        var it = std.mem.tokenizeScalar(u8, str, ' ');
        const d = it.next().?;
        const n = it.next().?;

        const dir: Dir = switch (d[0]) {
            'R' => .right,
            'L' => .left,
            'U' => .up,
            'D' => .down,
            else => @panic(d),
        };

        return .{
            .dir = dir,
            .count = try std.fmt.parseInt(i64, n, 10),
        };
    }

    fn fromStrPart2(str: []const u8) !@This() {
        var it = std.mem.tokenizeAny(u8, str, "#()");
        _ = it.next().?;
        const value = it.next().?;

        const dir: Dir = switch (value[5]) {
            '0' => .right,
            '1' => .down,
            '2' => .left,
            '3' => .up,
            else => @panic(value),
        };

        return .{
            .dir = dir,
            .count = try std.fmt.parseInt(i64, value[0..5], 16),
        };
    }
};

fn movePoint(p: Pos, op: Op) Pos {
    return switch (op.dir) {
        .up => .{ .x = p.x, .y = p.y - op.count },
        .down => .{ .x = p.x, .y = p.y + op.count },
        .left => .{ .x = p.x - op.count, .y = p.y },
        .right => .{ .x = p.x + op.count, .y = p.y },
    };
}

fn shoelaceFormula(points: []const Pos) u64 {
    var sum: i64 = 0;
    for (0..points.len) |i| {
        const prev = if (i == 0) points.len - 1 else i - 1;
        const next = if (i == points.len - 1) 0 else i + 1;
        sum += points[i].x * (points[prev].y - points[next].y);
    }
    return @abs(sum) / 2;
}

fn picksTheorem(area: u64, boundaries: u64) u64 {
    return area - boundaries / 2 + 1;
}

fn calculateArea(points: []const Pos, boundaries: u64) u64 {
    const a = shoelaceFormula(points);
    const i = picksTheorem(a, boundaries);
    return i + boundaries;
}

fn addPoint(points: *std.ArrayList(Pos), op: Op, boundaries: *u64) !void {
    boundaries.* += @intCast(op.count);
    const new = movePoint(points.getLast(), op);
    try points.append(new);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();

    var points1 = std.ArrayList(Pos).init(alloc);
    try points1.append(.{ .x = 0, .y = 0 });
    var points2 = std.ArrayList(Pos).init(alloc);
    try points2.append(.{ .x = 0, .y = 0 });
    var boundary_points1: u64 = 0;
    var boundary_points2: u64 = 0;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const op1 = try Op.fromStrPart1(line);
        const op2 = try Op.fromStrPart2(line);

        try addPoint(&points1, op1, &boundary_points1);
        try addPoint(&points2, op2, &boundary_points2);
    }

    const part1 = calculateArea(points1.items, boundary_points1);
    const part2 = calculateArea(points2.items, boundary_points2);
    std.debug.print("part 1: {d}\n", .{part1});
    std.debug.print("part 2: {d}\n", .{part2});
}
