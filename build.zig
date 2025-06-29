const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // const dvui_dep = b.dependency("dvui", .{
    //     .target = target,
    //     .optimize = optimize,
    //     .backend = .raylib,
    // });
    //
    const icons_dep = b.dependency("icons", .{});
    //
    // const exe_mod = b.createModule(.{
    //     .root_source_file = b.path("src/app.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    //
    // exe_mod.addImport("dvui", dvui_dep.module("dvui_raylib"));
    // exe_mod.addImport("icons", icons_dep.module("icons"));

    const dvui_dep = b.dependency("dvui", .{ .target = target, .optimize = optimize, .backend = .raylib });

    const exe = b.addExecutable(.{
        .name = "rplanner",
        .root_source_file = .{ .cwd_relative = "src/app.zig" },
        .target = target,
        .optimize = optimize,
        .use_lld = false,
    });

    exe.root_module.addImport("dvui", dvui_dep.module("dvui_raylib"));
    exe.root_module.addImport("icons", icons_dep.module("icons"));

    const compile_step = b.step("compile-" ++ "rplanner", "Compile " ++ "rplanner");
    compile_step.dependOn(&b.addInstallArtifact(exe, .{}).step);
    b.getInstallStep().dependOn(compile_step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(compile_step);

    const run_step = b.step("rplanner", "Run " ++ "rplanner");
    run_step.dependOn(&run_cmd.step);

    // const exe = b.addExecutable(.{
    //     .name = "rplanner",
    //     .root_module = exe_mod,
    //     .use_lld = false,
    // });
    //
    // b.installArtifact(exe);
    //
    // const run_step = b.step("run", "Run executable");
    //
    // const run_cmd = b.addRunArtifact(exe);
    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }
    // run_step.dependOn(&run_cmd.step);
    //
    // // ZLS Build-On-Save.
    // const exe_check = b.addExecutable(.{
    //     .name = "rplanner",
    //     .root_module = exe_mod,
    // });
    //
    // const check_step = b.step("check", "Check if rplanner compiles");
    // check_step.dependOn(&exe_check.step);
}
