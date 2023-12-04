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
    points: usize,

    fn fromStr(alloc: std.mem.Allocator, str: []const u8) !Card {
        var split = std.mem.tokenizeScalar(u8, str, ':');
        _ = split.next();

        const cards_str = split.next().?;
        var cards = std.mem.tokenizeScalar(u8, cards_str, '|');

        const winning = try createNumberSet(alloc, cards.next().?);
        const numbers = try createNumberSet(alloc, cards.next().?);

        var points: usize = 0;
        var it = winning.keyIterator();
        while (it.next()) |key| {
            if (numbers.contains(key.*)) points += 1;
        }

        return .{
            .points = points,
        };
    }
};

pub fn main() !void {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    var cards = [_]u32{1} ** 256;

    var points: usize = 0;
    var total_cards: usize = 0;
    var id: u32 = 0;
    while (lines.next()) |line_raw| : (id += 1) {
        const line = if (builtin.os.tag == .windows) std.mem.trim(u8, line_raw, "\r") else line_raw;

        const card = try Card.fromStr(allocator, line);
        points += if (card.points == 0) 0 else std.math.pow(usize, 2, card.points - 1);

        const count = cards[id];
        total_cards += count;

        const extra_cards = card.points;
        for (0..count) |_| {
            for (0..extra_cards) |i| {
                cards[id + i + 1] += 1;
            }
        }
    }

    std.debug.print("part 1: {d}\n", .{points});
    std.debug.print("part 2: {d}\n", .{total_cards});
}
