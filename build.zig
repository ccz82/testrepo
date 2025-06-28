const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dvui_dep = b.dependency("dvui", .{
        .target = target,
        .optimize = optimize,
        .backend = .sdl3,
    });

    const icons_dep = b.dependency("icons", .{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/app.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_mod.addImport("dvui", dvui_dep.module("dvui_sdl3"));
    exe_mod.addImport("icons", icons_dep.module("icons"));

    const exe = b.addExecutable(.{
        .name = "rplanner",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run executable");

    const run_cmd = b.addRunArtifact(exe);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    run_step.dependOn(&run_cmd.step);

    // ZLS Build-On-Save.
    const exe_check = b.addExecutable(.{
        .name = "rplanner",
        .root_module = exe_mod,
    });

    const check_step = b.step("check", "Check if rplanner compiles");
    check_step.dependOn(&exe_check.step);
}
