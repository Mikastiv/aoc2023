const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const src_dir = "src";
    var dir = try std.fs.cwd().openDir(src_dir, .{ .iterate = true });
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        switch (entry.kind) {
            .file => {
                if (!std.mem.endsWith(u8, entry.name, ".zig")) continue;
                if (!std.mem.startsWith(u8, entry.name, "day")) continue;

                const stem = std.fs.path.stem(entry.name);

                const filename = b.pathJoin(&.{ src_dir, entry.name });
                const exe = b.addExecutable(.{
                    .name = stem,
                    .root_source_file = .{ .path = filename },
                    .target = target,
                    .optimize = optimize,
                });

                const input_path = b.pathJoin(&.{ "data", stem });
                exe.addAnonymousModule("input", .{ .source_file = .{ .path = input_path } });
                b.installArtifact(exe);

                const run_cmd = b.addRunArtifact(exe);
                run_cmd.step.dependOn(b.getInstallStep());

                if (b.args) |args| {
                    run_cmd.addArgs(args);
                }

                const run_step = b.step(stem, "Run the day");
                run_step.dependOn(&run_cmd.step);
            },
            else => continue,
        }
    }
}
