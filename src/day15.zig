const std = @import("std");
const utils = @import("utils.zig");

const input = @embedFile("input");

fn hash(str: []const u8) usize {
    var h: usize = 0;
    for (str) |c| {
        h += c;
        h *= 17;
        h %= 256;
    }
    return h;
}

const Lens = struct {
    label: []const u8,
    focal: usize,

    fn fromStr(str: []const u8) !@This() {
        const idx = std.mem.indexOfScalar(u8, str, '=').?;
        const label = str[0..idx];
        const focal = try std.fmt.parseInt(usize, str[idx + 1 ..], 10);
        return .{
            .label = label,
            .focal = focal,
        };
    }
};

fn getLensByLabel(lenses: []const Lens, label: []const u8) ?usize {
    for (lenses, 0..) |lens, i| {
        if (std.mem.eql(u8, lens.label, label)) return i;
    }
    return null;
}

fn getLabel(str: []const u8) []const u8 {
    if (std.mem.indexOfScalar(u8, str, '-')) |idx| {
        return str[0..idx];
    } else {
        const idx = std.mem.indexOfScalar(u8, str, '=').?;
        return str[0..idx];
    }
}

const Op = enum {
    remove,
    add,

    fn get(str: []const u8) @This() {
        if (std.mem.indexOfScalar(u8, str, '-') != null)
            return .remove
        else
            return .add;
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();

    var steps = std.mem.tokenizeScalar(u8, std.mem.trim(u8, input, "\r\n"), ',');
    var boxes = std.AutoHashMap(usize, std.ArrayList(Lens)).init(alloc);
    var part1: usize = 0;
    while (steps.next()) |step| {
        part1 += hash(step);

        const label = getLabel(step);
        const h = hash(label);

        switch (Op.get(step)) {
            .remove => if (boxes.getPtr(h)) |ptr| {
                if (getLensByLabel(ptr.items, label)) |idx| {
                    _ = ptr.orderedRemove(idx);
                }
            },
            .add => {
                const lens = try Lens.fromStr(step);
                const entry = try boxes.getOrPut(h);
                if (entry.found_existing) {
                    if (getLensByLabel(entry.value_ptr.items, label)) |idx| {
                        entry.value_ptr.items[idx] = lens;
                    } else {
                        try entry.value_ptr.append(lens);
                    }
                } else {
                    var box = try std.ArrayList(Lens).initCapacity(alloc, 4);
                    try box.append(lens);
                    entry.value_ptr.* = box;
                }
            },
        }
    }

    var it = boxes.iterator();
    var part2: usize = 0;
    while (it.next()) |box| {
        for (box.value_ptr.items, 0..) |lens, idx| {
            part2 += (box.key_ptr.* + 1) * lens.focal * (idx + 1);
        }
    }

    std.debug.print("part 1: {d}\n", .{part1});
    std.debug.print("part 2: {d}\n", .{part2});
}
