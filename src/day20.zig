const std = @import("std");

const input = @embedFile("input");

const Module = struct {
    const Self = @This();
    const Type = enum { flipflop, conjunction };

    type: Type,
    buffer: [5][]const u8,
    outputs: usize,
    mem: union {
        flip: bool,
        conj: std.StringHashMap(bool),
    },

    fn fromStr(alloc: std.mem.Allocator, str: []const u8) struct { Self, []const u8 } {
        var it = std.mem.tokenizeSequence(u8, str, " -> ");
        const mod = it.next().?;
        const outs = it.next().?;

        var buffer: [5][]const u8 = undefined;
        var i: usize = 0;
        var outputs = std.mem.tokenizeSequence(u8, outs, ", ");
        while (outputs.next()) |part| : (i += 1) {
            buffer[i] = part;
        }

        const t = mod[0];
        const n = mod[1..];

        if (t == '%') {
            return .{
                .{
                    .type = .flipflop,
                    .buffer = buffer,
                    .outputs = i,
                    .mem = .{ .flip = false },
                },
                n,
            };
        } else {
            std.debug.assert(t == '&');
            return .{
                .{
                    .type = .conjunction,
                    .buffer = buffer,
                    .outputs = i,
                    .mem = .{ .conj = std.StringHashMap(bool).init(alloc) },
                },
                n,
            };
        }
    }
};

fn getRxFeed(modules: *const std.StringHashMap(Module)) []const u8 {
    var it = modules.iterator();
    while (it.next()) |entry| {
        const m = entry.value_ptr.*;
        for (0..m.outputs) |i| {
            if (std.mem.eql(u8, m.buffer[i], "rx")) return entry.key_ptr.*;
        }
    }
    @panic("no rx output");
}

fn lcm(a: u64, b: u64) u64 {
    return (a * b) / std.math.gcd(a, b);
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();

    var modules = std.StringHashMap(Module).init(alloc);
    var start = std.ArrayList([]const u8).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "broadcaster")) {
            var parts = std.mem.tokenizeSequence(u8, line[15..], ", ");
            while (parts.next()) |p| {
                try start.append(p);
            }
        } else {
            const m, const name = Module.fromStr(alloc, line);
            try modules.putNoClobber(name, m);
        }
    }

    var it = modules.iterator();
    while (it.next()) |entry| {
        const m = entry.value_ptr;
        for (0..m.outputs) |i| {
            const other = modules.getPtr(m.buffer[i]);
            if (other == null) continue;
            switch (other.?.type) {
                .conjunction => try other.?.mem.conj.putNoClobber(entry.key_ptr.*, false),
                else => {},
            }
        }
    }

    const rx_feed = getRxFeed(&modules);
    var cycles = std.StringHashMap(usize).init(alloc);

    var lo: u64 = 0;
    var hi: u64 = 0;
    var queue = std.ArrayList(struct { []const u8, []const u8, bool }).init(alloc);
    var press: usize = 1;
    while (true) : (press += 1) {
        if (cycles.count() == 4 and press >= 1000) break;

        if (press <= 1000) lo += 1;
        for (start.items) |item| {
            try queue.append(.{ "broadcaster", item, false });
        }

        while (queue.items.len > 0) {
            const origin, const target, const pulse = queue.orderedRemove(0);
            if (press <= 1000) {
                if (pulse) hi += 1 else lo += 1;
            }

            const module = modules.getPtr(target);
            if (module == null) continue;

            if (std.mem.eql(u8, target, rx_feed) and pulse) {
                _ = try cycles.getOrPutValue(origin, press);
            }

            const m = module.?;
            switch (m.type) {
                .flipflop => if (!pulse) {
                    m.mem.flip = !m.mem.flip;
                    for (0..m.outputs) |i| {
                        try queue.append(.{ target, m.buffer[i], m.mem.flip });
                    }
                },
                .conjunction => {
                    const mem = m.mem.conj.getPtr(origin);
                    if (mem != null) mem.?.* = pulse;

                    var signal = false;
                    var mem_it = m.mem.conj.iterator();
                    while (mem_it.next()) |entry| {
                        if (!entry.value_ptr.*) {
                            signal = true;
                            break;
                        }
                    }

                    for (0..m.outputs) |i| {
                        try queue.append(.{ target, m.buffer[i], signal });
                    }
                },
            }
        }
    }

    var cycs = cycles.iterator();
    var part2 = cycs.next().?.value_ptr.*;
    while (cycs.next()) |c| {
        part2 = lcm(part2, c.value_ptr.*);
    }

    std.debug.print("part 1: {d}\n", .{lo * hi});
    std.debug.print("part 2: {d}\n", .{part2});
}
