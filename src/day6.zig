const std = @import("std");
const utils = @import("utils.zig");

const input = @embedFile("input");

const ValuesArray = std.BoundedArray(i64, 8);

fn parseNumberList(line: []const u8) !ValuesArray {
    const str = utils.windowsTrim(line);

    var out = try ValuesArray.init(0);

    var parts = std.mem.tokenizeScalar(u8, str, ':');
    _ = parts.next();

    var it = std.mem.tokenizeScalar(u8, parts.next().?, ' ');
    while (it.next()) |num_str| {
        const num = try std.fmt.parseInt(i64, num_str, 10);
        try out.append(num);
    }

    return out;
}

fn parseSingleNumber(alloc: std.mem.Allocator, line: []const u8) !i64 {
    const str = utils.windowsTrim(line);

    var parts = std.mem.tokenizeScalar(u8, str, ':');
    _ = parts.next();

    var number_parts = try std.BoundedArray([]const u8, 8).init(0);

    var it = std.mem.tokenizeScalar(u8, parts.next().?, ' ');
    while (it.next()) |num| {
        try number_parts.append(num);
    }

    const number_str = try std.mem.concat(alloc, u8, number_parts.constSlice());

    return std.fmt.parseInt(i64, number_str, 10);
}

fn solveRace(time: i64, distance: i64) i64 {
    const mid = @divFloor(time, 2);

    var i = mid;
    const low = blk: while (mid > 0) : (i -= 1) {
        if (!(i * (time - i) > distance)) break :blk i + 1;
    } else {
        break :blk 1;
    };

    i = mid;
    const high = blk: while (mid < time) : (i += 1) {
        if (!(i * (time - i) > distance)) break :blk i;
    } else {
        break :blk time;
    };

    return high - low;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    const time_str = lines.next().?;
    const dist_str = lines.next().?;

    const times = try parseNumberList(time_str);
    const distances = try parseNumberList(dist_str);

    const single_time = try parseSingleNumber(alloc, time_str);
    const single_distance = try parseSingleNumber(alloc, dist_str);

    var product: i64 = 1;
    for (times.constSlice(), distances.constSlice()) |time, dist| {
        product *= solveRace(time, dist);
    }

    const big_race = solveRace(single_time, single_distance);

    std.debug.print("part 1: {d}\n", .{product});
    std.debug.print("part 2: {d}\n", .{big_race});
}
