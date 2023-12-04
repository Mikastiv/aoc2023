const std = @import("std");
const builtin = @import("builtin");

const input = @embedFile("input");

const Vec2 = [2]i32;

const Symbol = struct {
    pos: Vec2,
    char: u8,
};

const PartNumber = struct {
    const Self = @This();

    value: i32,
    pos: Vec2,
    len: i32,
    seen: bool,

    fn fromStr(x: i32, y: i32, str: []const u8) !Self {
        const value = try std.fmt.parseInt(i32, str, 10);
        return .{
            .value = value,
            .pos = .{ x, y },
            .len = @intCast(str.len),
            .seen = false,
        };
    }

    fn isAdjacent(self: Self, symbol: Vec2) bool {
        const min_x = @max(self.pos[0] - 1, 0);
        const max_x = self.pos[0] + self.len;
        const min_y = @max(self.pos[1] - 1, 0);
        const max_y = self.pos[1] + 1;

        return (symbol[0] >= min_x and symbol[0] <= max_x) and (symbol[1] >= min_y and symbol[1] <= max_y);
    }
};

pub fn main() !void {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    var symbols = std.ArrayList(Symbol).init(allocator);
    var numbers = std.ArrayList(PartNumber).init(allocator);

    var y: i32 = 0;
    while (lines.next()) |line_raw| : (y += 1) {
        const line = if (builtin.os.tag == .windows) std.mem.trim(u8, line_raw, "\r") else line_raw;

        var x: i32 = 0;
        var skip = false;

        while (x < line.len) : (x += 1) {
            const char = line[@intCast(x)];
            const is_digit = std.ascii.isDigit(char);
            const is_symbol = !is_digit and char != '.';

            if (is_digit) {
                if (skip) continue;

                skip = true;
                const substr = line[@intCast(x)..];
                const number_end = std.mem.indexOfNone(u8, substr, "0123456789") orelse substr.len;
                const part_number = try PartNumber.fromStr(x, y, substr[0..number_end]);
                try numbers.append(part_number);
                continue;
            }

            skip = false;
            if (is_symbol) try symbols.append(.{ .pos = .{ x, y }, .char = char });
        }
    }

    var sum: i32 = 0;
    for (numbers.items) |*num| {
        for (symbols.items) |sym| {
            if (!num.seen and num.isAdjacent(sym.pos)) {
                num.seen = true;
                sum += num.value;
            }
        }
    }

    var ratio_sum: i32 = 0;
    for (symbols.items) |sym| {
        var part_count: i32 = 0;
        var product: i32 = 1;
        for (numbers.items) |num| {
            if (sym.char == '*' and num.isAdjacent(sym.pos)) {
                part_count += 1;
                product *= num.value;
            }
        }

        if (part_count == 2) ratio_sum += product;
    }

    std.debug.print("part 1: {d}\n", .{sum});
    std.debug.print("part 2: {d}\n", .{ratio_sum});
}
