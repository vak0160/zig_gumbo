const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("gumbo", .{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const lib_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const lib = b.addLibrary(.{
        .name = "gumbo",
        .linkage = .static,
        .root_module = lib_mod,
    });

    var arena = std.heap.ArenaAllocator.init(b.allocator);
    defer arena.deinit();
    const aa = arena.allocator();

    var flags_arr = std.array_list.Aligned([]const u8, null).empty;

    switch (optimize) {
        .ReleaseFast, .ReleaseSmall => {
            try flags_arr.append(aa, "-O3");
        },
        else => {},
    }

    lib_mod.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &.{
            "attribute.c",
            "char_ref.c",
            "error.c",
            "parser.c",
            "string_buffer.c",
            "string_piece.c",
            "tag.c",
            "tokenizer.c",
            "utf8.c",
            "util.c",
            "vector.c",
        },
        .flags = flags_arr.items,
    });

    lib_mod.addIncludePath(upstream.path("src"));

    lib.installHeadersDirectory(upstream.path("src"), "", .{});

    b.installArtifact(lib);
}
