const std = @import("std");
const utils = @import("utils.zig");

const input = @embedFile("input");

const Node = struct {
    l: []const u8,
    r: []const u8,
};

const Instructions = struct {
    list: []const u8,
    current: usize,

    fn next(self: *@This()) u8 {
        const value = self.list[self.current];
        self.current += 1;
        self.current %= self.list.len;
        return value;
    }
};

fn lcm(a: u64, b: u64) u64 {
    return (a * b) / std.math.gcd(a, b);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var instructions = Instructions{
        .list = utils.windowsTrim(lines.next().?),
        .current = 0,
    };

    var nodes = std.StringHashMap(Node).init(alloc);
    var ghost_nodes = std.ArrayList([]const u8).init(alloc);

    while (lines.next()) |line_raw| {
        const line = utils.windowsTrim(line_raw);

        var parts = std.mem.tokenizeSequence(u8, line, " = ");

        const name = parts.next().?;

        var elements_parts = std.mem.tokenizeAny(u8, parts.next().?, "(), ");
        const left = elements_parts.next().?;
        const right = elements_parts.next().?;

        try nodes.putNoClobber(name, Node{ .l = left, .r = right });
        if (name[2] == 'A') try ghost_nodes.append(name);
    }

    var part1: u64 = 0;
    var current: []const u8 = "AAA";
    while (!std.mem.eql(u8, current, "ZZZ")) : (part1 += 1) {
        const inst = instructions.next();
        const entry = nodes.get(current);
        if (inst == 'L') {
            current = entry.?.l;
        } else {
            current = entry.?.r;
        }
    }

    var steps: u64 = 0;
    var counts = std.ArrayList(u64).init(alloc);
    for (ghost_nodes.items) |*node| {
        steps = 0;
        instructions.current = 0;
        while (node.*[2] != 'Z') : (steps += 1) {
            const inst = instructions.next();
            const entry = nodes.get(node.*);
            if (inst == 'L') {
                node.* = entry.?.l;
            } else {
                node.* = entry.?.r;
            }
        }
        try counts.append(steps);
    }

    var part2 = counts.items[0];
    for (1..counts.items.len) |i| {
        part2 = lcm(part2, counts.items[i]);
    }

    std.debug.print("part 1: {d}\n", .{part1});
    std.debug.print("part 2: {d}\n", .{part2});
}
