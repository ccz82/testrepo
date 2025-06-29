const std = @import("std");
const dvui = @import("dvui");
const icons = @import("icons").tvg.lucide;

const Rplanner = @import("Rplanner.zig");
const RplannerLight = @import("themes/light.zig").Theme;
const RplannerDark = @import("themes/dark.zig").Theme;

// Declare "dvui_app".
pub const dvui_app: dvui.App = .{
    .config = .{
        .options = .{
            .min_size = .{ .w = 640.0, .h = 480.0 },
            .size = .{ .w = 1920.0, .h = 1080.0 },
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
var da = std.heap.DebugAllocator(.{}){};
const allocator = da.allocator();

// Initialize global state in `Rplanner`.
var rplanner = Rplanner{};

pub fn init(win: *dvui.Window) !void {
    try dvui.addFont(
        "Lato",
        @embedFile("fonts/Lato-Regular.ttf"),
        null,
    );

    win.theme = RplannerDark;
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

    menubar();

    tabbar();

    toolbar();

    {
        dvui.Examples.show_demo_window = true;
        dvui.Examples.demo();
        dvui.Examples.scrollCanvas();
    }

    return switch (rplanner.running) {
        true => .ok,
        false => .close,
    };
}

pub fn deinit() void {
    switch (da.deinit()) {
        .leak => std.log.err("leak!!!", .{}),
        .ok => {},
    }
}

fn menubar() void {
    var m = dvui.menu(
        @src(),
        .horizontal,
        .{
            .expand = .horizontal,
            .background = true,
            .color_fill = .{ .name = .fill },
        },
    );
    defer m.deinit();

    if (dvui.menuItemLabel(
        @src(),
        "File",
        .{ .submenu = true },
        .{
            .expand = .none,
            .padding = .{ .x = 5, .w = 5 },
            .corner_radius = .all(0),
        },
    )) |r| {
        var fm = dvui.floatingMenu(
            @src(),
            .{ .from = r },
            .{
                .padding = .all(0),
                .corner_radius = .all(0),
            },
        );
        defer fm.deinit();
    }

    if (dvui.menuItemLabel(
        @src(),
        "Edit",
        .{ .submenu = true },
        .{
            .expand = .none,
            .corner_radius = .all(0),
            .padding = .{ .x = 5, .w = 5 },
        },
    )) |r| {
        var fm = dvui.floatingMenu(@src(), .{ .from = r }, .{ .corner_radius = .all(0) });
        defer fm.deinit();
        _ = dvui.menuItemLabel(@src(), "Dummy", .{}, .{ .expand = .horizontal });
        _ = dvui.menuItemLabel(@src(), "Dummy Long", .{}, .{ .expand = .horizontal });
        _ = dvui.menuItemLabel(@src(), "Dummy Super Long", .{}, .{ .expand = .horizontal });
    }

    if (dvui.menuItemLabel(
        @src(),
        "View",
        .{ .submenu = true },
        .{
            .expand = .none,
            .corner_radius = .all(0),
            .padding = .{ .x = 5, .w = 5 },
        },
    )) |r| {
        var fm = dvui.floatingMenu(@src(), .{ .from = r }, .{ .corner_radius = .all(0) });
        defer fm.deinit();
        _ = dvui.checkbox(@src(), &rplanner.show_recent_blocks, "Recent Blocks", .{});
        _ = dvui.checkbox(@src(), &rplanner.show_placed_blocks, "Placed Blocks", .{});
    }

    if (dvui.menuItemLabel(
        @src(),
        "Window",
        .{ .submenu = true },
        .{
            .expand = .none,
            .corner_radius = .all(0),
            .padding = .{ .x = 5, .w = 5 },
        },
    )) |r| {
        var fm = dvui.floatingMenu(@src(), .{ .from = r }, .{ .corner_radius = .all(0) });
        defer fm.deinit();
        if (dvui.button(@src(), "Zoom In", .{}, .{})) {
            rplanner.scale = @round(dvui.themeGet().font_body.size * rplanner.scale + 1.0) / dvui.themeGet().font_body.size;
            // invalidate = true;
        }

        if (dvui.button(@src(), "Zoom Out", .{}, .{})) {
            rplanner.scale = @round(dvui.themeGet().font_body.size * rplanner.scale - 1.0) / dvui.themeGet().font_body.size;
            // invalidate = true;
        }
    }
}

fn tabbar() void {
    var tabs = dvui.TabsWidget.init(
        @src(),
        .{ .dir = .horizontal },
        .{ .expand = .horizontal },
    );
    tabs.install();
    defer tabs.deinit();

    for (0.., rplanner.files) |i, filename| {
        var tab = tabs.addTab(
            rplanner.open_file == i,
            .{
                .padding = .all(1),
                .color_fill_press = if (rplanner.open_file == i) .{ .name = .fill_window } else .{ .name = .fill_hover },
                .color_fill_hover = if (rplanner.open_file == i) .{ .name = .fill_window } else .{ .name = .fill_hover },
            },
        );
        defer tab.deinit();

        var hbox = dvui.box(@src(), .horizontal, .{ .expand = .horizontal });
        defer hbox.deinit();

        var label_opts = tab.data().options.strip();
        if (dvui.captured(tab.data().id)) {
            label_opts.color_text = .text_press;
        }

        dvui.label(@src(), "{s}", .{filename}, label_opts);

        if (tab.clicked()) {
            rplanner.open_file = i;
        }
    }
}

fn toolbar() void {
    var hbox = dvui.box(@src(), .horizontal, .{ .expand = .horizontal });
    defer hbox.deinit();

    if (dvui.buttonIcon(@src(), "Move", icons.hand, .{}, .{}, .{})) {
        rplanner.tool = .move;
        dvui.cursorSet(.hand);
    }

    if (dvui.buttonIcon(@src(), "Draw", icons.brush, .{}, .{}, .{})) {
        rplanner.tool = .draw;
    }

    if (dvui.buttonIcon(@src(), "Erase", icons.eraser, .{}, .{}, .{})) {
        rplanner.tool = .erase;
    }

    if (dvui.buttonIcon(@src(), "Paint Bucket", icons.@"paint-bucket", .{}, .{}, .{})) {
        rplanner.tool = .paint_bucket;
    }

    dvui.label(@src(), "selected tool: {}", .{rplanner.tool}, .{});
}
