const std = @import("std");
const utils = @import("utils.zig");

const input = @embedFile("input");

const ValuesArray = std.BoundedArray(u64, 8);

fn parseNumberList(line: []const u8) !ValuesArray {
    const str = utils.windowsTrim(line);

    var out = try ValuesArray.init(0);

    var parts = std.mem.tokenizeScalar(u8, str, ':');
    _ = parts.next();

    var it = std.mem.tokenizeScalar(u8, parts.next().?, ' ');
    while (it.next()) |num_str| {
        const num = try std.fmt.parseInt(u64, num_str, 10);
        try out.append(num);
    }

    return out;
}

fn parseSingleNumber(alloc: std.mem.Allocator, line: []const u8) !u64 {
    const str = utils.windowsTrim(line);

    var parts = std.mem.tokenizeScalar(u8, str, ':');
    _ = parts.next();

    var number_parts = try std.BoundedArray([]const u8, 8).init(0);

    var it = std.mem.tokenizeScalar(u8, parts.next().?, ' ');
    while (it.next()) |num| {
        try number_parts.append(num);
    }

    const number_str = try std.mem.concat(alloc, u8, number_parts.constSlice());

    return std.fmt.parseInt(u64, number_str, 10);
}

fn solveRace(time: u64, distance: u64) u64 {
    var solutions: u64 = 0;

    for (0..time) |t| {
        if (t * (time - t) > distance) solutions += 1;
    }

    return solutions;
}

fn quadraticSolve(time: u64, distance: u64) u64 {
    // travel time (t) = race time (r) - time pressed (p)
    // traveled distance (d) = travel time (t) * time pressed (p);
    // t = r - p
    // d = t * p
    //
    // substitute
    // d = (r - p) * p
    // d = pr - p2
    // p2 - pr + d = 0

    const r: f64 = @floatFromInt(time);
    const d: f64 = @floatFromInt(distance);

    // a = 1, b = -r, c = d
    const discriminant_root = @sqrt(std.math.pow(f64, r, 2) - 4.0 * d);
    const high = (r + discriminant_root) / 2.0;
    const low = (r - discriminant_root) / 2.0;

    return @as(u64, @intFromFloat(high)) - @as(u64, @intFromFloat(low));
}

pub fn main() !void {
    @setEvalBranchQuota(2000);

    const part1, const part2 = comptime blk: {
        var buffer: [256]u8 = undefined;
        var fixed = std.heap.FixedBufferAllocator.init(&buffer);
        const alloc = fixed.allocator();

        var lines = std.mem.tokenizeScalar(u8, input, '\n');

        const time_str = lines.next().?;
        const dist_str = lines.next().?;

        const times = try parseNumberList(time_str);
        const distances = try parseNumberList(dist_str);

        const single_time = try parseSingleNumber(alloc, time_str);
        const single_distance = try parseSingleNumber(alloc, dist_str);

        var product: u64 = 1;
        for (times.constSlice(), distances.constSlice()) |time, dist| {
            product *= quadraticSolve(time, dist);
        }

        break :blk .{ product, quadraticSolve(single_time, single_distance) };
    };

    std.debug.print("part 1: {d}\n", .{part1});
    std.debug.print("part 2: {d}\n", .{part2});
}
