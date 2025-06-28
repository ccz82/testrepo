const Self = @This();

const std = @import("std");
const dvui = @import("dvui");

running: bool = true,

scale: f32 = 1.0,

show_recent_blocks: bool = true,
show_placed_blocks: bool = true,

files: [4][]const u8 = .{ "welcome", "hello", "nice", "last" },
open_file: usize = 0,
