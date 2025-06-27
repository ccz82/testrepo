const std = @import("std");
const dvui = @import("dvui");

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

    var tbox = dvui.box(@src(), .vertical, .{ .max_size_content = .{ .w = 400, .h = 200 } });
    defer tbox.deinit();

    {
        var tabs = dvui.TabsWidget.init(@src(), .{ .dir = .horizontal }, .{ .expand = .horizontal });
        tabs.install();
        defer tabs.deinit();

        for (0.., rplanner.files) |i, file| {
            if (tabs.addTabLabel(rplanner.open_file == i, file)) {
                rplanner.open_file = i;
            }
        }
    }

    {
        var hbox = dvui.box(@src(), .horizontal, .{
            .expand = .both,
            .background = true,
            .color_fill = .{ .name = .fill_window },
        });
        defer hbox.deinit();

        dvui.label(@src(), "This is tab {d}", .{rplanner.open_file}, .{
            .expand = .both,
            .gravity_x = 0.5,
            .gravity_y = 0.5,
        });
    }

    {
        dvui.Examples.show_demo_window = true;
        dvui.Examples.demo();
    }
    // dvui.Examples.scrollCanvas();

    return .ok;
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
            .corner_radius = dvui.Rect.all(0),
            .padding = .{ .x = 6, .w = 6 },
        },
    )) |r| {
        var fm = dvui.floatingMenu(@src(), .{ .from = r }, .{ .corner_radius = dvui.Rect.all(0) });
        defer fm.deinit();

        if (dvui.menuItemLabel(@src(), "Close Menu", .{}, .{})) |_| {
            m.close();
        }
    }

    if (dvui.menuItemLabel(
        @src(),
        "Edit",
        .{ .submenu = true },
        .{
            .expand = .none,
            .corner_radius = dvui.Rect.all(0),
            .padding = .{ .x = 6, .w = 6 },
        },
    )) |r| {
        var fm = dvui.floatingMenu(@src(), .{ .from = r }, .{ .corner_radius = dvui.Rect.all(0) });
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
            .corner_radius = dvui.Rect.all(0),
            .padding = .{ .x = 6, .w = 6 },
        },
    )) |r| {
        var fm = dvui.floatingMenu(@src(), .{ .from = r }, .{ .corner_radius = dvui.Rect.all(0) });
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
            .corner_radius = dvui.Rect.all(0),
            .padding = .{ .x = 6, .w = 6 },
        },
    )) |r| {
        var fm = dvui.floatingMenu(@src(), .{ .from = r }, .{ .corner_radius = dvui.Rect.all(0) });
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

fn sidebar() void {
    var sb = dvui.box(@src(), .vertical, .{
        .expand = .vertical,
        .background = true,
        .color_fill = .{ .name = .fill_window },
    });
    defer sb.deinit();
    _ = dvui.label(@src(), "sidebar", .{}, .{});
    if (rplanner.show_recent_blocks) {
        _ = dvui.label(@src(), "recent blocks!", .{}, .{});
    }
    if (rplanner.show_placed_blocks) {
        _ = dvui.label(@src(), "placed blocks!", .{}, .{});
    }
}

fn viewport() void {
    var vp = dvui.box(@src(), .vertical, .{
        .expand = .both,
        .background = true,
        .color_fill = .{ .color = .fromHex("#ffffff") },
    });
    defer vp.deinit();
    _ = dvui.label(@src(), "viewport", .{}, .{});
}
