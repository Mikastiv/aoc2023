const std = @import("std");
const utils = @import("utils.zig");

const input = @embedFile("input");

const Hand = struct {
    const Strength = enum(u32) {
        high_card,
        one_pair,
        two_pair,
        three_of_a_kind,
        full_house,
        four_of_a_kind,
        five_of_a_kind,
    };

    cards: [5]u8,
    bid: u64,

    fn fromStr(str: []const u8) !@This() {
        var it = std.mem.tokenizeScalar(u8, str, ' ');
        const cards = it.next().?;
        const bid_str = it.next().?;

        const bid = try std.fmt.parseInt(u64, bid_str, 10);

        return .{
            .cards = cards[0..5].*,
            .bid = bid,
        };
    }

    fn strength(self: @This(), use_jokers: bool) !Strength {
        var buffer: [512]u8 = undefined;
        var fixed = std.heap.FixedBufferAllocator.init(&buffer);
        const alloc = fixed.allocator();

        var hash_map = std.AutoHashMap(u8, u32).init(alloc);

        for (self.cards) |card| {
            const entry = try hash_map.getOrPut(card);
            if (entry.found_existing)
                entry.value_ptr.* += 1
            else
                entry.value_ptr.* = 1;
        }

        const joker_count = if (use_jokers) blk: {
            const entry = hash_map.fetchRemove('J') orelse break :blk 0;
            break :blk entry.value;
        } else 0;

        var entries = std.ArrayList(u32).init(alloc);
        var it = hash_map.valueIterator();
        while (it.next()) |value| {
            try entries.append(value.*);
        }

        std.sort.insertion(u32, entries.items, {}, std.sort.desc(u32));

        if (use_jokers and joker_count > 0) {
            if (joker_count == 5) try entries.append(0);
            entries.items[0] += joker_count;
        }

        if (entries.items.len == 1) return .five_of_a_kind;
        if (entries.items.len == 5) return .high_card;
        if (entries.items.len == 4) return .one_pair;

        if (entries.items.len == 3) {
            if (entries.items[0] == 3)
                return .three_of_a_kind
            else
                return .two_pair;
        }

        if (entries.items[0] == 4)
            return .four_of_a_kind
        else
            return .full_house;
    }

    fn compare(use_jokers: bool, a: @This(), b: @This()) bool {
        const card_strength = "_23456789TJQKA";
        const j_strength = comptime std.mem.indexOfScalar(u8, card_strength, 'J').?;

        const strength_a: u32 = @intFromEnum(a.strength(use_jokers) catch unreachable);
        const strength_b: u32 = @intFromEnum(b.strength(use_jokers) catch unreachable);

        if (strength_a != strength_b) return strength_a < strength_b;

        for (0..a.cards.len) |i| {
            var card_a = std.mem.indexOfScalar(u8, card_strength, a.cards[i]).?;
            var card_b = std.mem.indexOfScalar(u8, card_strength, b.cards[i]).?;

            if (use_jokers) {
                if (card_a == j_strength) card_a = 0;
                if (card_b == j_strength) card_b = 0;
            }

            if (card_a != card_b) return card_a < card_b;
        }

        return false;
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var hands = std.ArrayList(Hand).init(alloc);

    while (lines.next()) |line_raw| {
        const line = utils.windowsTrim(line_raw);

        const hand = try Hand.fromStr(line);
        try hands.append(hand);
    }

    std.sort.pdq(Hand, hands.items, false, Hand.compare);

    var winnings1: u64 = 0;
    for (hands.items, 1..) |hand, rank| {
        winnings1 += hand.bid * rank;
    }

    std.sort.pdq(Hand, hands.items, true, Hand.compare);

    var winnings2: u64 = 0;
    for (hands.items, 1..) |hand, rank| {
        winnings2 += hand.bid * rank;
    }

    std.debug.print("part 1: {d}\n", .{winnings1});
    std.debug.print("part 2: {d}\n", .{winnings2});
}
