const std = @import("std");

const input = @embedFile("input");

const Part = enum(u8) {
    x = 0,
    m = 1,
    a = 2,
    s = 3,

    fn fromChar(char: u8) @This() {
        return switch (char) {
            'x' => .x,
            'm' => .m,
            'a' => .a,
            's' => .s,
            else => @panic(""),
        };
    }
};

const Cmp = enum {
    lt,
    gt,

    fn compare(self: @This(), a: u16, b: u16) bool {
        return switch (self) {
            .lt => a < b,
            .gt => a > b,
        };
    }
};

const Rule = struct {
    part: Part,
    cmp: Cmp,
    value: u16,
    next: []const u8,

    fn fromStr(str: []const u8) !@This() {
        var parts = std.mem.tokenizeScalar(u8, str[2..], ':');
        const v = parts.next().?;
        const n = parts.next().?;

        const part = Part.fromChar(str[0]);

        const cmp: Cmp = switch (str[1]) {
            '>' => .gt,
            '<' => .lt,
            else => @panic(str),
        };

        return .{
            .part = part,
            .cmp = cmp,
            .value = try std.fmt.parseInt(u16, v, 10),
            .next = n,
        };
    }
};

const Entry = union(enum) {
    rule: Rule,
    default: []const u8,
};

const Rating = struct {
    part: Part,
    value: u16,
};

fn parseWorkflows(alloc: std.mem.Allocator, str: []const u8) !std.StringHashMap([]Entry) {
    var lines = std.mem.tokenizeScalar(u8, str, '\n');
    var workflows = std.StringHashMap([]Entry).init(alloc);
    while (lines.next()) |line| {
        const idx = std.mem.indexOfScalar(u8, line, '{').?;
        const name = line[0..idx];
        var it = std.mem.tokenizeScalar(u8, std.mem.trim(u8, line[idx..], "{}"), ',');
        var entries = std.ArrayList(Entry).init(alloc);
        while (it.next()) |entry| {
            if (std.mem.indexOfScalar(u8, entry, ':') != null) {
                const rule = try Rule.fromStr(entry);
                try entries.append(.{ .rule = rule });
            } else {
                try entries.append(.{ .default = entry });
            }
        }
        try workflows.putNoClobber(name, try entries.toOwnedSlice());
    }

    return workflows;
}

fn parseRatings(alloc: std.mem.Allocator, str: []const u8) !std.ArrayList([4]Rating) {
    var lines = std.mem.tokenizeScalar(u8, str, '\n');
    var ratings = std.ArrayList([4]Rating).init(alloc);
    while (lines.next()) |line| {
        var it = std.mem.tokenizeScalar(u8, std.mem.trim(u8, line, "{}"), ',');
        var current: [4]Rating = undefined;
        while (it.next()) |rating| {
            const part = Part.fromChar(rating[0]);
            const value = try std.fmt.parseInt(u16, rating[2..], 10);
            const i: usize = @intFromEnum(part);
            current[i] = .{ .part = part, .value = value };
        }
        try ratings.append(current);
    }
    return ratings;
}

fn sumParts(ratings: [4]Rating) u64 {
    var sum: u64 = 0;
    for (ratings) |r| {
        sum += r.value;
    }
    return sum;
}

fn partAccepted(ratings: [4]Rating, workflows: *const std.StringHashMap([]Entry)) bool {
    var key: []const u8 = "in";
    while (workflows.get(key)) |workflow| {
        for (workflow) |entry| {
            switch (entry) {
                .default => |d| {
                    key = d;
                    break;
                },
                .rule => |r| {
                    const idx: usize = @intFromEnum(r.part);
                    if (r.cmp.compare(ratings[idx].value, r.value)) {
                        key = r.next;
                        break;
                    }
                },
            }
        }
        if (std.mem.eql(u8, key, "A")) return true;
        if (std.mem.eql(u8, key, "R")) return false;
    }
    return false;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();

    var parts = std.mem.tokenizeSequence(u8, input, "\n\n");
    const workflows = try parseWorkflows(alloc, parts.next().?);
    const ratings = try parseRatings(alloc, parts.next().?);
    var part1: usize = 0;
    for (ratings.items) |rating| {
        if (partAccepted(rating, &workflows)) part1 += sumParts(rating);
    }

    std.debug.print("part 1: {d}\n", .{part1});
}
