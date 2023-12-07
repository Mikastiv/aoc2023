const std = @import("std");
const utils = @import("utils.zig");

const input = @embedFile("input");

const Card = enum(u32) {
    two = 1,
    three,
    four,
    five,
    six,
    seven,
    eight,
    nine,
    ten,
    jack,
    queen,
    king,
    ace,

    fn fromChar(char: u8) @This() {
        return switch (char) {
            '2' => .two,
            '3' => .three,
            '4' => .four,
            '5' => .five,
            '6' => .six,
            '7' => .seven,
            '8' => .eight,
            '9' => .nine,
            'T' => .ten,
            'J' => .jack,
            'Q' => .queen,
            'K' => .king,
            'A' => .ace,
            else => unreachable,
        };
    }
};

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

    cards: [5]Card,
    bid: u64,

    fn fromStr(str: []const u8) !@This() {
        var it = std.mem.tokenizeScalar(u8, str, ' ');
        const cards_str = it.next().?;
        const bid_str = it.next().?;

        var cards: [5]Card = undefined;
        for (cards_str, 0..) |char, i| {
            cards[i] = Card.fromChar(char);
        }

        const bid = try std.fmt.parseInt(u64, bid_str, 10);

        return .{
            .cards = cards,
            .bid = bid,
        };
    }

    fn strength(self: @This(), use_jokers: bool) Strength {
        var buffer: [512]u8 = undefined;
        var fixed = std.heap.FixedBufferAllocator.init(&buffer);
        const alloc = fixed.allocator();

        var hash_map = std.AutoHashMap(Card, u32).init(alloc);

        for (self.cards) |card| {
            const entry = hash_map.getOrPut(card) catch unreachable;
            if (entry.found_existing)
                entry.value_ptr.* += 1
            else
                entry.value_ptr.* = 1;
        }

        const joker_count = blk: {
            const ptr = hash_map.getPtr(.jack) orelse break :blk 0;
            break :blk ptr.*;
        };

        var entries = std.ArrayList(u32).init(alloc);
        var it = hash_map.iterator();
        while (it.next()) |entry| {
            entries.append(entry.value_ptr.*) catch unreachable;
        }

        std.sort.insertion(u32, entries.items, {}, std.sort.desc(u32));

        if (entries.items.len == 1) return .five_of_a_kind;

        if (use_jokers) {
            if (entries.items.len == 5) {
                if (joker_count > 0)
                    return .one_pair
                else
                    return .high_card;
            }

            if (entries.items.len == 4) {
                if (joker_count > 0)
                    return .three_of_a_kind
                else
                    return .one_pair;
            }

            if (entries.items.len == 3) {
                if (entries.items[0] == 3) {
                    if (joker_count > 0)
                        return .four_of_a_kind
                    else
                        return .three_of_a_kind;
                } else {
                    if (joker_count == 2) return .four_of_a_kind;
                    if (joker_count == 1) return .full_house;
                    return .two_pair;
                }
            }

            if (entries.items[0] == 4) {
                if (joker_count > 0)
                    return .five_of_a_kind
                else
                    return .four_of_a_kind;
            } else {
                if (joker_count > 0)
                    return .five_of_a_kind
                else
                    return .full_house;
            }
        } else {
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
    }

    fn compare(use_jokers: bool, a: @This(), b: @This()) bool {
        const strength_a: u32 = @intFromEnum(a.strength(use_jokers));
        const strength_b: u32 = @intFromEnum(b.strength(use_jokers));

        if (strength_a != strength_b) return strength_a < strength_b;

        for (0..a.cards.len) |i| {
            var card_a: u32 = @intFromEnum(a.cards[i]);
            var card_b: u32 = @intFromEnum(b.cards[i]);

            if (use_jokers) {
                if (card_a == @intFromEnum(Card.jack)) card_a = 0;
                if (card_b == @intFromEnum(Card.jack)) card_b = 0;
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
