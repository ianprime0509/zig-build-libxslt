const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const upstream = b.dependency("libxslt", .{});

    const libxml2 = b.dependency("libxml2", .{
        .target = target,
        .optimize = optimize,
        .html = true,
        .output = true,
        .tree = true,
        .xpath = true,
    });

    const libxslt = b.addStaticLibrary(.{
        .name = "xslt",
        .target = target,
        .optimize = optimize,
    });
    libxslt.linkLibC();
    libxslt.linkLibrary(libxml2.artifact("xml2"));

    libxslt.addIncludePath(upstream.path("."));
    libxslt.addIncludePath(.{ .path = "override/include" });
    if (target.result.os.tag == .windows) {
        @panic("TODO: Windows support");
    } else {
        libxslt.addIncludePath(.{ .path = "override/config/posix" });
        // TODO: why?
        libxslt.installHeader("override/config/posix/config.h", "config.h");
    }

    var libxslt_flags = std.ArrayList([]const u8).init(b.allocator);
    libxslt_flags.appendSlice(&.{
        comptime "-DLIBXSLT_VERSION=" ++ xslt_version.number(),
        comptime "-DLIBXSLT_VERSION_STRING=" ++ xslt_version.string(),
        "-DLIBXSLT_VERSION_EXTRA=\"\"",
        comptime "-DLIBXSLT_DOTTED_VERSION=" ++ xslt_version.dottedString(),
        // TODO: zig-build-libxml doesn't correctly set these in xmlversion.h
        "-DLIBXML_VERSION=201105",
        "-DLIBXML_HTML_ENABLED",
        "-DLIBXML_OUTPUT_ENABLED",
        "-DLIBXML_TREE_ENABLED",
        "-DLIBXML_XPATH_ENABLED",
    }) catch @panic("OOM");
    libxslt.addCSourceFiles(.{
        .dependency = upstream,
        .files = &.{
            "libxslt/attributes.c",
            "libxslt/attrvt.c",
            "libxslt/documents.c",
            "libxslt/extensions.c",
            "libxslt/extra.c",
            "libxslt/functions.c",
            "libxslt/imports.c",
            "libxslt/keys.c",
            "libxslt/namespaces.c",
            "libxslt/numbers.c",
            "libxslt/pattern.c",
            "libxslt/preproc.c",
            "libxslt/security.c",
            "libxslt/templates.c",
            "libxslt/transform.c",
            "libxslt/variables.c",
            "libxslt/xslt.c",
            "libxslt/xsltlocale.c",
            "libxslt/xsltutils.c",
        },
        .flags = libxslt_flags.items,
    });
    libxslt.installHeader("override/include/libxslt/xsltconfig.h", "libxslt/xsltconfig.h");
    libxslt.installHeadersDirectoryOptions(.{
        .source_dir = upstream.path("libxslt"),
        .install_dir = .header,
        .install_subdir = "libxslt",
        .include_extensions = &.{".h"},
    });

    b.installArtifact(libxslt);

    const libexslt = b.addStaticLibrary(.{
        .name = "exslt",
        .target = target,
        .optimize = optimize,
    });
    libexslt.linkLibC();
    libexslt.linkLibrary(libxml2.artifact("xml2"));
    libexslt.linkLibrary(libxslt);

    libexslt.addIncludePath(upstream.path("."));
    libexslt.addIncludePath(.{ .path = "override/include" });
    if (target.result.os.tag == .windows) {
        @panic("TODO: Windows support");
    } else {
        libexslt.addIncludePath(.{ .path = "override/config/posix" });
    }

    var libexslt_flags = std.ArrayList([]const u8).init(b.allocator);
    libexslt_flags.appendSlice(&.{
        comptime "-DLIBEXSLT_VERSION=" ++ exslt_version.number(),
        comptime "-DLIBEXSLT_VERSION_STRING=" ++ exslt_version.string(),
        "-DLIBEXSLT_VERSION_EXTRA=\"\"",
        comptime "-DLIBEXSLT_DOTTED_VERSION=" ++ exslt_version.dottedString(),
        // TODO: not exposed through library header
        comptime "-DLIBXSLT_VERSION=" ++ xslt_version.number(),
        comptime "-DLIBXSLT_VERSION_STRING=" ++ xslt_version.string(),
        "-DLIBXSLT_VERSION_EXTRA=\"\"",
        comptime "-DLIBXSLT_DOTTED_VERSION=" ++ xslt_version.dottedString(),
        // TODO: zig-build-libxml doesn't correctly set these in xmlversion.h
        "-DLIBXML_VERSION=201105",
        "-DLIBXML_HTML_ENABLED",
        "-DLIBXML_OUTPUT_ENABLED",
        "-DLIBXML_TREE_ENABLED",
        "-DLIBXML_XPATH_ENABLED",
    }) catch @panic("OOM");
    libexslt.addCSourceFiles(.{
        .dependency = upstream,
        .files = &.{
            "libexslt/common.c",
            "libexslt/crypto.c",
            "libexslt/date.c",
            "libexslt/dynamic.c",
            "libexslt/exslt.c",
            "libexslt/functions.c",
            "libexslt/math.c",
            "libexslt/saxon.c",
            "libexslt/sets.c",
            "libexslt/strings.c",
        },
        .flags = libexslt_flags.items,
    });
    libexslt.installHeader("override/include/libexslt/exsltconfig.h", "libexslt/exsltconfig.h");
    libexslt.installHeadersDirectoryOptions(.{
        .source_dir = upstream.path("libexslt"),
        .install_dir = .header,
        .install_subdir = "libexslt",
        .include_extensions = &.{".h"},
    });

    b.installArtifact(libexslt);

    const xsltproc = b.addExecutable(.{
        .name = "xsltproc",
        .target = target,
        .optimize = optimize,
    });
    xsltproc.linkLibC();
    xsltproc.linkLibrary(libxml2.artifact("xml2"));
    xsltproc.linkLibrary(libxslt);
    xsltproc.linkLibrary(libexslt);
    xsltproc.addCSourceFile(.{
        .file = upstream.path("xsltproc/xsltproc.c"),
        .flags = &.{
            // TODO: why is this not included in zig-build-libxml2?
            "-DLIBXML_TEST_VERSION=",
            // TODO: sigh
            comptime "-DLIBEXSLT_VERSION=" ++ exslt_version.number(),
            comptime "-DLIBEXSLT_VERSION_STRING=" ++ exslt_version.string(),
            "-DLIBEXSLT_VERSION_EXTRA=\"\"",
            comptime "-DLIBEXSLT_DOTTED_VERSION=" ++ exslt_version.dottedString(),
            // TODO: not exposed through library header
            comptime "-DLIBXSLT_VERSION=" ++ xslt_version.number(),
            comptime "-DLIBXSLT_VERSION_STRING=" ++ xslt_version.string(),
            "-DLIBXSLT_VERSION_EXTRA=\"\"",
            comptime "-DLIBXSLT_DOTTED_VERSION=" ++ xslt_version.dottedString(),
            // TODO: zig-build-libxml doesn't correctly set these in xmlversion.h
            "-DLIBXML_VERSION=201105",
            "-DLIBXML_HTML_ENABLED",
            "-DLIBXML_OUTPUT_ENABLED",
            "-DLIBXML_TREE_ENABLED",
            "-DLIBXML_XPATH_ENABLED",
        },
    });
    b.installArtifact(xsltproc);

    inline for (std.meta.fields(Options)) |field| {
        const opt = b.option(bool, field.name, "Configure flag") orelse
            @as(*const bool, @ptrCast(field.default_value.?)).*;
        if (opt) {
            var nameBuf: [32]u8 = undefined;
            const name = std.ascii.upperString(&nameBuf, field.name);

            if (std.mem.eql(u8, field.name, "crypto")) {
                // This one follows a different define convention for some
                // reason.
                libxslt_flags.append("-DEXSLT_CRYPTO_ENABLED") catch @panic("OOM");
            } else {
                libxslt_flags.append(b.fmt("-DWITH_{s}", .{name})) catch @panic("OOM");
            }

            if (std.mem.eql(u8, field.name, "mem_debug")) {
                libxslt_flags.appendSlice(&.{
                    "-DDEBUG_MEMORY",
                    "-DDEBUG_MEMORY_LOCATION",
                }) catch @panic("OOM");
            }
        }
    }
}

// TODO: parse these from somewhere
pub const xslt_version: Version = .{ .major = "1", .minor = "1", .micro = "39" };
pub const exslt_version: Version = .{ .major = "0", .minor = "8", .micro = "21" };

pub const Version = struct {
    major: []const u8,
    minor: []const u8,
    micro: []const u8,

    pub fn number(version: Version) []const u8 {
        const version_fmt = std.fmt.comptimePrint("{s:0>2}{s:0>2}{s:0>2}", .{ version.major, version.minor, version.micro });
        return std.mem.trimLeft(u8, version_fmt, "0");
    }

    pub fn string(version: Version) []const u8 {
        return "\"" ++ version.number() ++ "\"";
    }

    pub fn dottedString(version: Version) []const u8 {
        return "\"" ++ version.major ++ "." ++ version.minor ++ "." ++ version.micro ++ "\"";
    }
};

/// Compile-time options for the library, corresponding to the `--with` options
/// defined in `configure.ac`.
const Options = struct {
    xslt_debug: bool = true,
    mem_debug: bool = false,
    debugger: bool = true,
    profiler: bool = true,
    plugins: bool = true,
    modules: bool = true, // TODO: should also be passed to libxml2 configure
    crypto: bool = true,
};
