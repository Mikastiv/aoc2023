const std = @import("std");
const builtin = @import("builtin");

const input = @embedFile("input");

fn createNumberSet(alloc: std.mem.Allocator, str: []const u8) !std.AutoHashMap(u32, void) {
    var it = std.mem.tokenizeScalar(u8, str, ' ');
    var out = std.AutoHashMap(u32, void).init(alloc);
    while (it.next()) |num| {
        const n = try std.fmt.parseInt(u32, num, 10);
        try out.putNoClobber(n, {});
    }

    return out;
}

const Card = struct {
    id: u32,
    winning: std.AutoHashMap(u32, void),
    numbers: std.AutoHashMap(u32, void),

    fn fromStr(alloc: std.mem.Allocator, str: []const u8) !Card {
        var split = std.mem.splitScalar(u8, str, ':');
        var split_id = std.mem.tokenizeScalar(u8, split.first(), ' ');
        _ = split_id.next();
        const id = try std.fmt.parseInt(u32, split_id.next().?, 10);

        const cards_str = split.next() orelse return error.InvalidFormat;
        var cards = std.mem.splitScalar(u8, cards_str, '|');

        const winning = try createNumberSet(alloc, cards.next().?);
        const numbers = try createNumberSet(alloc, cards.next().?);

        return .{
            .id = id,
            .winning = winning,
            .numbers = numbers,
        };
    }

    fn points(self: *const Card) usize {
        var total: usize = 0;
        var it = self.winning.keyIterator();
        while (it.next()) |key| {
            if (self.numbers.getKey(key.*)) |_| {
                if (total == 0) total = 1 else total *= 2;
            }
        }

        return total;
    }

    fn scratchcards(self: *const Card) usize {
        var total: usize = 0;
        var it = self.winning.keyIterator();
        while (it.next()) |key| {
            if (self.numbers.getKey(key.*)) |_| {
                total += 1;
            }
        }

        return total;
    }
};

fn addOneCard(stacks: *std.AutoHashMap(u32, u32), id: u32) !u32 {
    const entry = try stacks.getOrPut(id);
    if (entry.found_existing) {
        entry.value_ptr.* += 1;
    } else {
        entry.value_ptr.* = 1;
    }

    return entry.value_ptr.*;
}

pub fn main() !void {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    var stacks = std.AutoHashMap(u32, u32).init(allocator);
    try stacks.ensureTotalCapacity(256);

    var points: usize = 0;
    var total_cards: usize = 0;
    while (lines.next()) |line_raw| {
        const line = if (builtin.os.tag == .windows) std.mem.trim(u8, line_raw, "\r") else line_raw;

        const card = try Card.fromStr(allocator, line);
        points += card.points();

        const id = card.id;
        const count = try addOneCard(&stacks, id);
        total_cards += count;

        const extra_card = card.scratchcards();
        for (0..count) |_| {
            for (0..extra_card) |i| {
                _ = try addOneCard(&stacks, @intCast(i + id + 1));
            }
        }
    }

    std.debug.print("part 1: {d}\n", .{points});
    std.debug.print("part 2: {d}\n", .{total_cards});
}
