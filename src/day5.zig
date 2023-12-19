const std = @import("std");

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
    end: u64,
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

    fn mappableInterval(self: Range, interval: Interval) bool {
        return self.src <= interval.end and self.src + self.len > interval.start;
    }

    fn mapInterval(self: Range, interval: Interval) Interval {
        const len = interval.end - interval.start;
        const diff = interval.start - self.src;
        return .{
            .start = self.dst + diff,
            .end = self.dst + diff + len,
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

    fn mapInterval(self: *const @This(), alloc: std.mem.Allocator, interval: Interval) ![]Interval {
        var intervals = std.ArrayList(Interval).init(alloc);
        defer intervals.deinit();

        var mapped_intervals = std.ArrayList(Interval).init(alloc);

        for (self.ranges.constSlice()) |range| {
            if (range.mappableInterval(interval)) {
                const section = Interval{
                    .start = @max(range.src, interval.start),
                    .end = @min(range.src + range.len, interval.end),
                };
                try intervals.append(section);
                try mapped_intervals.append(range.mapInterval(section));
            }
        }

        std.sort.insertion(Interval, intervals.items, {}, intervalCompare);

        var curr: u64 = interval.start;
        for (intervals.items) |int| {
            if (curr < int.start) {
                try mapped_intervals.append(.{ .start = curr, .end = int.start });
            }
            curr = int.end;
        }

        if (mapped_intervals.items.len == 0) {
            try mapped_intervals.append(.{ .start = interval.start, .end = interval.end });
        }

        return mapped_intervals.toOwnedSlice();
    }
};

fn intervalCompare(_: void, lhs: Interval, rhs: Interval) bool {
    return lhs.start < rhs.start;
}

const SeedArray = std.BoundedArray(u64, 32);

fn parseSeeds(str: []const u8) !SeedArray {
    var seeds = try SeedArray.init(0);

    var parts = std.mem.tokenizeScalar(u8, str, ':');
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

    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    const seeds = try parseSeeds(lines.next().?);
    var maps = std.EnumArray(Category, Map).initFill(try Map.init());

    var category: ?Category = null;

    // parse input
    while (lines.next()) |line| {
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

    // part 1
    var smallest_location: u32 = std.math.maxInt(u32);
    for (seeds.constSlice()) |seed| {
        var value = seed;

        var it = maps.iterator();
        while (it.next()) |entry| {
            value = entry.value.mapValue(value);
        }

        smallest_location = @min(smallest_location, value);
    }

    // part 2
    var intervals = std.ArrayList(Interval).init(alloc);
    var temp = std.ArrayList(Interval).init(alloc);

    // create seeds intervals
    var i: usize = 0;
    while (i < seeds.len) : (i += 2) {
        const seed_start = seeds.constSlice()[i];
        const len = seeds.constSlice()[i + 1];
        try intervals.append(.{ .start = seed_start, .end = seed_start + len });
    }

    // remap intervals
    var it = maps.iterator();
    while (it.next()) |map| {
        for (intervals.items) |int| {
            const new_intervals = try map.value.mapInterval(alloc, int);
            defer alloc.free(new_intervals);
            try temp.appendSlice(new_intervals);
        }
        intervals.clearAndFree();
        intervals = std.ArrayList(Interval).fromOwnedSlice(alloc, try temp.toOwnedSlice());
    }

    var smallest_location_2: u32 = std.math.maxInt(u32);
    for (intervals.items) |int| {
        smallest_location_2 = @min(smallest_location_2, int.start);
    }

    std.debug.print("part 1: {d}\n", .{smallest_location});
    std.debug.print("part 2: {d}\n", .{smallest_location_2});
}
