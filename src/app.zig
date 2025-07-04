const std = @import("std");
const dvui = @import("dvui");

const Rplanner = @import("Rplanner.zig");
const RplannerLight = @import("themes/light.zig").Theme;
const RplannerDark = @import("themes/dark.zig").Theme;

const SCREEN_WIDTH_PX = 1280;
const SCREEN_HEIGHT_PX = 720;

// Declare "dvui_app".
pub const dvui_app: dvui.App = .{
    .config = .{
        .options = .{
            .size = .{ .w = SCREEN_WIDTH_PX, .h = SCREEN_HEIGHT_PX },
            .title = "rplanner",
            // .icon = window_icon_png,
        },
    },
    .initFn = init,
    .frameFn = frame,
    .deinitFn = deinit,
};

// Use dvui main, panic and log functions.
pub const main = dvui.App.main;
pub const panic = dvui.App.panic;
pub const std_options: std.Options = .{ .logFn = dvui.App.logFn };

// Initialize memory allocator.
var da = std.heap.DebugAllocator(.{}).init;
const allocator = da.allocator();

// Initialize global state in `Rplanner`.
var rplanner: Rplanner = undefined;

pub fn init(win: *dvui.Window) !void {
    try dvui.addFont(
        "Lato",
        @embedFile("fonts/Lato-Regular.ttf"),
        null,
    );

    win.theme = win.themes.get("Adwaita Light").?;

    rplanner = try Rplanner.init(allocator, win.backend.impl.renderer);
}

pub fn frame() !dvui.App.Result {
    var scaler = dvui.scale(
        @src(),
        .{ .scale = &rplanner.scale },
        .{
            .expand = .both,
            .background = true,
            .color_fill = .{ .name = .fill_window },
        },
    );
    defer scaler.deinit();

    try rplanner.menubar();

    rplanner.tabbar();

    var hbox = dvui.box(
        @src(),
        .horizontal,
        .{
            .expand = .both,
            .background = true,
            .color_fill = .{ .name = .fill_window },
        },
    );
    defer hbox.deinit();

    rplanner.sidebar();

    rplanner.content();

    dvui.Examples.show_demo_window = rplanner.show_demo;
    dvui.Examples.demo();

    return switch (rplanner.running) {
        true => .ok,
        false => .close,
    };
}

pub fn deinit() void {
    rplanner.deinit();
    switch (da.deinit()) {
        .leak => std.log.err("leak!!!", .{}),
        .ok => {},
    }
}
