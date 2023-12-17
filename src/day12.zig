const std = @import("std");
const utils = @import("utils.zig");

const input = @embedFile("input");

const Range = struct {
    start: usize,
    end: usize,
};

const Record = struct {
    buffer: [256]u8,
    list: Range,
    gs: Range,

    fn init(list: []const u8, groups_str: []const u8) !@This() {
        var buffer: [256]u8 = undefined;
        @memcpy(buffer[0..list.len], list);

        var it = std.mem.tokenizeScalar(u8, groups_str, ',');
        var i = list.len;
        while (it.next()) |group| : (i += 1) {
            const num = try std.fmt.parseInt(u8, group, 10);
            buffer[i] = num;
        }

        return .{
            .buffer = buffer,
            .list = .{ .start = 0, .end = list.len },
            .gs = .{ .start = list.len, .end = i },
        };
    }

    fn groups(self: *const @This()) []const u8 {
        return self.buffer[self.gs.start..self.gs.end];
    }

    fn sequence(self: *const @This()) []const u8 {
        return self.buffer[self.list.start..self.list.end];
    }
};

const DP_State = struct {
    i: usize,
    gi: usize,
    len: usize,
};

fn solveLine(
    state: *std.AutoHashMap(DP_State, usize),
    seq: []const u8,
    groups: []const u8,
    seq_i: usize,
    groups_i: usize,
    current_len: usize,
) !usize {
    const key = DP_State{ .i = seq_i, .gi = groups_i, .len = current_len };
    if (state.get(key)) |value| return value;

    // end of record
    if (seq_i == seq.len) {
        // if not in a group; ok
        if (groups_i == groups.len and current_len == 0) return 1;
        // if ending a group of the right len; ok
        if (groups_i == groups.len - 1 and current_len == groups[groups_i]) return 1;
        // else; not ok
        return 0;
    }

    var result: usize = 0;
    for ([2]u8{ '.', '#' }) |c| {
        const curr = seq[seq_i];

        // c != current char in seq and c != ?
        if (!(curr == c or curr == '?')) continue;

        if (c == '.' and current_len == 0) // if not in group and len == 0; advance seq index
            result += try solveLine(state, seq, groups, seq_i + 1, groups_i, 0)
        else if (c == '.' and groups_i < groups.len and groups[groups_i] == current_len) // ending a group; advance seq index and group index
            result += try solveLine(state, seq, groups, seq_i + 1, groups_i + 1, 0)
        else if (c == '#') // if #; advance seq index and group len
            result += try solveLine(state, seq, groups, seq_i + 1, groups_i, current_len + 1);
    }

    try state.putNoClobber(key, result);

    return result;
}

fn solve(alloc: std.mem.Allocator, records: []Record) !usize {
    var state = std.AutoHashMap(DP_State, usize).init(alloc);
    var result: usize = 0;
    for (records) |record| {
        result += try solveLine(&state, record.sequence(), record.groups(), 0, 0, 0);
        state.clearRetainingCapacity();
    }
    return result;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();

    var records1 = std.ArrayList(Record).init(alloc);
    var records2 = std.ArrayList(Record).init(alloc);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    while (lines.next()) |line_raw| {
        const line = utils.windowsTrim(line_raw);

        var it = std.mem.tokenizeScalar(u8, line, ' ');
        const list = it.next().?;
        const groups = it.next().?;

        const record = try Record.init(list, groups);
        try records1.append(record);

        const list_five = try std.mem.join(alloc, "?", &.{ list, list, list, list, list });
        const groups_five = try std.mem.join(alloc, ",", &.{ groups, groups, groups, groups, groups });

        const record_five = try Record.init(list_five, groups_five);
        try records2.append(record_five);
    }

    const part1 = try solve(alloc, records1.items);
    const part2 = try solve(alloc, records2.items);

    std.debug.print("part 1: {d}\n", .{part1});
    std.debug.print("part 2: {d}\n", .{part2});
}
