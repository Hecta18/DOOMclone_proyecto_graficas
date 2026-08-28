const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("raylib", raylib);

    const exe = b.addExecutable(.{
        .name = "laberinth",
        .root_module = exe_mod,
    });
    exe.root_module.linkLibrary(raylib_artifact);
    b.installArtifact(exe);

    b.installDirectory(.{
        .source_dir = b.path("resources"),
        .install_dir = .bin,
        .install_subdir = "resources",
    });

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run Laberinth");
    run_step.dependOn(&run_cmd.step);
}
