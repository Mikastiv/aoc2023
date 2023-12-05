const std = @import("std");
const utils = @import("utils.zig");

const input = @embedFile("input");

const Category = enum {
    seed_to_soil,
    soil_to_fertilizer,
    fertilizer_to_water,
    water_to_light,
    light_to_temperature,
    temperature_to_humidity,
    humidity_to_location,

    fn fromStr(str: []const u8) Category {
        if (std.mem.eql(u8, str, "seed-to-soil map")) return .seed_to_soil;
        if (std.mem.eql(u8, str, "soil-to-fertilizer map")) return .soil_to_fertilizer;
        if (std.mem.eql(u8, str, "fertilizer-to-water map")) return .fertilizer_to_water;
        if (std.mem.eql(u8, str, "water-to-light map")) return .water_to_light;
        if (std.mem.eql(u8, str, "light-to-temperature map")) return .light_to_temperature;
        if (std.mem.eql(u8, str, "temperature-to-humidity map")) return .temperature_to_humidity;
        if (std.mem.eql(u8, str, "humidity-to-location map")) return .humidity_to_location;
        unreachable;
    }
};

const Interval = struct {
    start: u64,
    len: u64,
};

const Range = struct {
    dst: u64,
    src: u64,
    len: u64,

    fn fromStr(str: []const u8) !Range {
        var parts = std.mem.tokenizeScalar(u8, str, ' ');
        const dst = try std.fmt.parseInt(u64, parts.next().?, 10);
        const src = try std.fmt.parseInt(u64, parts.next().?, 10);
        const len = try std.fmt.parseInt(u64, parts.next().?, 10);

        return .{
            .dst = dst,
            .src = src,
            .len = len,
        };
    }

    fn mappable(self: Range, n: u64) bool {
        return n >= self.src and n < self.src + self.len;
    }

    fn map(self: Range, n: u64) u64 {
        const diff = n - self.src;
        return self.dst + diff;
    }

    fn interval(self: Range, n: u64) ?Interval {
        if (!self.mappable(n)) return null;

        const diff = n - self.src;
        return .{
            .start = n,
            .len = self.len - diff,
        };
    }

    fn mapInterval(self: Range, i: Interval) Interval {
        return .{
            .start = self.dst,
            .len = i.len,
        };
    }
};

const RangeArray = std.BoundedArray(Range, 64);

const Map = struct {
    ranges: RangeArray,

    fn init() !Map {
        return .{
            .ranges = try RangeArray.init(0),
        };
    }

    fn mapValue(self: *const @This(), value: u64) u64 {
        for (self.ranges.constSlice()) |range| {
            if (range.mappable(value)) {
                return range.map(value);
            }
        }
        return value;
    }
};

const SeedArray = std.BoundedArray(u64, 32);

fn parseSeeds(str: []const u8) !SeedArray {
    const line = utils.windowsTrim(str);

    var seeds = try SeedArray.init(0);

    var parts = std.mem.tokenizeScalar(u8, line, ':');
    _ = parts.next();

    var numbers = std.mem.tokenizeScalar(u8, parts.next().?, ' ');
    while (numbers.next()) |n| {
        try seeds.append(try std.fmt.parseInt(u32, n, 10));
    }

    return seeds;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();
    _ = alloc;

    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    const seeds = try parseSeeds(lines.next().?);
    var maps = std.EnumArray(Category, Map).initFill(try Map.init());

    var category: ?Category = null;

    while (lines.next()) |line_raw| {
        const line = utils.windowsTrim(line_raw);

        var parts = std.mem.tokenizeScalar(u8, line, ':');
        if (std.mem.indexOfScalar(u8, line, ':') != null) {
            const ident = parts.next().?;
            category = Category.fromStr(ident);
        }

        switch (category.?) {
            else => {
                const range_str = parts.next();
                if (range_str == null) continue;

                const range = try Range.fromStr(range_str.?);
                const ptr = maps.getPtr(category.?);
                try ptr.ranges.append(range);
            },
        }
    }

    var smallest_location: u32 = std.math.maxInt(u32);
    for (seeds.constSlice()) |seed| {
        var value = seed;

        var it = maps.iterator();
        while (it.next()) |entry| {
            value = entry.value.mapValue(value);
        }

        smallest_location = @min(smallest_location, value);
    }

    // var intervals = std.ArrayList(Interval).init(alloc);
    // var temp = std.ArrayList(Interval).init(alloc);

    // var i: usize = 0;
    // while (i < seeds.len) : (i += 2) {
    //     const seed_start = seeds.constSlice()[i];
    //     const len = seeds.constSlice()[i + 1];
    //     try intervals.append(.{ .start = seed_start, .len = len });
    // }

    // var it = maps.iterator();
    // _ = it.next();
    // while (it.next()) |map| {
    //     for (intervals.items) |int| {
    //         var curr = int.start;
    //         while (curr < int.start + int.len) {
    //             for (map.value.constSlice()) |range| {
    //                 const mappable_range = range.interval(curr);
    //                 if (mappable_range == null) continue;

    //                 std.debug.print("mapped: {any}\n", .{mappable_range.?});

    //                 curr += mappable_range.?.len;
    //                 try temp.append(range.mapInterval(mappable_range.?));
    //                 break;
    //             } else {
    //                 loop: for (curr..int.start + int.len) |n| {
    //                     for (map.value.constSlice()) |range| {
    //                         if (range.mappable(n)) {
    //                             try temp.append(.{ .start = curr, .len = n - curr });
    //                             curr = n;
    //                             break :loop;
    //                         }
    //                     }
    //                 } else {
    //                     try temp.append(.{ .start = curr, .len = curr - (int.start + int.len) });
    //                     curr += int.len;
    //                 }
    //             }
    //         }
    //     }

    //     intervals = std.ArrayList(Interval).fromOwnedSlice(alloc, try temp.toOwnedSlice());
    // }

    // var smallest_location_2: u32 = std.math.maxInt(u32);
    // for (intervals.items) |int| {
    //     smallest_location_2 = @min(smallest_location_2, int.start);
    // }

    std.debug.print("part 1: {d}\n", .{smallest_location});
    // std.debug.print("part 2: {d}\n", .{smallest_location_2});
}
