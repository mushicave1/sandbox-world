const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "my-exe",
        .root_source_file = b.path("main.zig"),
        .target = target,
        .optimize = optimize
    });

    const lib_path = std.Build.LazyPath{.cwd_relative = "/opt/homebrew/lib"};
    const include_path = std.Build.LazyPath{.cwd_relative = "/opt/homebrew/include"};

    exe.addLibraryPath(lib_path);
    exe.addIncludePath(include_path);
    exe.linkSystemLibrary("glfw");
    exe.linkSystemLibrary("epoxy");
    exe.linkLibC();

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "run the compiled and linked exe");
    run_step.dependOn(&run_exe.step);

    b.installArtifact(exe);
}
