const Self = @This();

const std = @import("std");
const dvui = @import("dvui");

scale: f32 = 1.0,

// Menubar: View
show_recent_blocks: bool = true,
show_placed_blocks: bool = true,
show_blocks_window: bool = false,

files: [4][]const u8 = .{ "welcome", "hello", "nice", "last" },
open_file: usize = 0,
