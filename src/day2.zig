const std = @import("std");
const utils = @import("utils.zig");

const input = @embedFile("input");

const Game = struct {
    const prefix = "Game ";

    id: u32,
    red: u32,
    green: u32,
    blue: u32,

    fn fromStr(str: []const u8) !Game {
        const colon = std.mem.indexOfScalar(u8, str, ':') orelse return error.InvalidFormat;
        const id = try std.fmt.parseInt(u32, str[prefix.len..colon], 10);

        var red: u32 = 0;
        var green: u32 = 0;
        var blue: u32 = 0;
        var it = std.mem.tokenizeSequence(u8, str[colon + 2 ..], "; ");
        while (it.next()) |round| {
            var dice = std.mem.tokenizeSequence(u8, round, ", ");
            while (dice.next()) |die| {
                var parts = std.mem.tokenizeScalar(u8, die, ' ');
                const n = parts.next() orelse return error.InvalidFormat;
                const color = parts.next() orelse return error.InvalidFormat;

                const num = try std.fmt.parseInt(u32, n, 10);
                if (std.mem.eql(u8, "red", color)) {
                    red = @max(red, num);
                } else if (std.mem.eql(u8, "green", color)) {
                    green = @max(green, num);
                } else if (std.mem.eql(u8, "blue", color)) {
                    blue = @max(blue, num);
                }
            }
        }

        return .{
            .id = id,
            .red = red,
            .green = green,
            .blue = blue,
        };
    }
};

pub fn main() !void {
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var sum: u32 = 0;
    var power: u32 = 0;
    while (lines.next()) |line_raw| {
        const line = utils.windowsTrim(line_raw);

        const game = try Game.fromStr(line);
        if (game.red <= 12 and game.green <= 13 and game.blue <= 14) {
            sum += game.id;
        }
        power += game.red * game.green * game.blue;
    }

    std.debug.print("part 1: {d}\n", .{sum});
    std.debug.print("part 2: {d}\n", .{power});
}
