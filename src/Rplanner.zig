const Rplanner = @This();

const Rplan = @import("Rplan.zig");

const std = @import("std");
const dvui = @import("dvui");
const sdl = dvui.backend.c;
const sdl_image = @cImport({
    @cInclude("SDL3_image/SDL_image.h");
});
const icons = @import("icons").tvg.lucide;

const TILE_SIZE_PX = 16;
const TILE_HEIGHT_EXTRA_PX = 8;
const TILE_TALL_SIZE_PC = TILE_SIZE_PX + TILE_HEIGHT_EXTRA_PX;

const REALM_WIDTH_TILES = 300;
const REALM_HEIGHT_TILES = 170;

const BG_WIDTH_PX = TILE_SIZE_PX * REALM_WIDTH_TILES;
const BG_HEIGHT_PX = TILE_SIZE_PX * REALM_HEIGHT_TILES;

const NORTH = 1;
const SOUTH = 2;
const EAST = 4;
const WEST = 8;

pub const Camera = struct {
    x: f32 = 0,
    y: f32 = 0,
    w: f32 = 0,
    h: f32 = 0,
    zoom: f32 = 1.0,
};

pub const Tool = enum {
    move,
    draw,
    erase,
    paint_bucket,
};

allocator: std.mem.Allocator,
running: bool = true,
scale: f32 = 1.0,
show_home_tab: bool = true,
show_grid: bool = true,
show_recent_blocks: bool = true,
show_placed_blocks: bool = true,
show_demo: bool = false,
rplans: std.ArrayListUnmanaged(Rplan) = .empty,
selected_rplan: ?usize = null,
tool: Tool = .draw,
previous_tool: Tool = .draw,
is_panning: bool = false,
sdl_renderer: *sdl.SDL_Renderer,
viewport_texture: *sdl.SDL_Texture,
forest_bg_texture: [*c]sdl.SDL_Texture,
bedrock_texture: [*c]sdl.SDL_Texture,
dirt_texture: [*c]sdl.SDL_Texture,
camera: Camera = .{},

pub fn init(allocator: std.mem.Allocator, sdl_renderer: *sdl.SDL_Renderer) !Rplanner {
    const forest_bg_texture = sdl.SDL_CreateTextureFromSurface(
        sdl_renderer,
        @ptrCast(sdl_image.IMG_Load("forest.png")),
    );
    _ = sdl.SDL_SetTextureScaleMode(forest_bg_texture, sdl.SDL_SCALEMODE_NEAREST);

    const bedrock_texture = sdl.SDL_CreateTextureFromSurface(
        sdl_renderer,
        @ptrCast(sdl_image.IMG_Load("bedrock.png")),
    );
    _ = sdl.SDL_SetTextureScaleMode(bedrock_texture, sdl.SDL_SCALEMODE_NEAREST);

    const dirt_texture = sdl.SDL_CreateTextureFromSurface(
        sdl_renderer,
        @ptrCast(sdl_image.IMG_Load("dirt.png")),
    );
    _ = sdl.SDL_SetTextureScaleMode(dirt_texture, sdl.SDL_SCALEMODE_NEAREST);

    const viewport_texture = sdl.SDL_CreateTexture(
        sdl_renderer,
        sdl.SDL_PIXELFORMAT_RGBA8888,
        sdl.SDL_TEXTUREACCESS_TARGET,
        BG_WIDTH_PX,
        BG_HEIGHT_PX,
    );
    _ = sdl.SDL_SetTextureScaleMode(viewport_texture, sdl.SDL_SCALEMODE_NEAREST);

    return Rplanner{
        .allocator = allocator,
        .sdl_renderer = sdl_renderer,
        .viewport_texture = viewport_texture,
        .forest_bg_texture = forest_bg_texture,
        .bedrock_texture = bedrock_texture,
        .dirt_texture = dirt_texture,
    };
}

pub fn deinit(rplanner: *Rplanner) void {
    rplanner.rplans.deinit(rplanner.allocator);

    if (rplanner.forest_bg_texture) |texture| {
        sdl.SDL_DestroyTexture(texture);
    }
    if (rplanner.bedrock_texture) |texture| {
        sdl.SDL_DestroyTexture(texture);
    }
    if (rplanner.dirt_texture) |texture| {
        sdl.SDL_DestroyTexture(texture);
    }

    sdl.SDL_DestroyTexture(rplanner.viewport_texture);
}

fn viewport(rplanner: *Rplanner) void {
    var box = dvui.box(
        @src(),
        .horizontal,
        .{
            .expand = .both,
            .margin = .all(10),
        },
    );
    defer box.deinit();

    const widget_data = box.data();
    const rs = widget_data.contentRectScale();

    // const context_menu = dvui.context(@src(), .{ .rect = rs.r }, .{});
    // defer context_menu.deinit();

    rplanner.camera.w = rs.r.w;
    rplanner.camera.h = rs.r.h;

    for (dvui.events()) |*event| {
        switch (event.evt) {
            .key => |key| {
                if (key.code == .space) {
                    if (key.action == .down) {
                        rplanner.previous_tool = rplanner.tool;
                        rplanner.tool = .move;
                        // event.handle(@src(), widget_data);
                    } else if (key.action == .up) {
                        rplanner.tool = rplanner.previous_tool;
                        // event.handle(@src(), widget_data);
                    }
                }
            },
            .mouse => |mouse| {
                if (rs.r.contains(mouse.p)) {
                    switch (mouse.action) {
                        .press => if (mouse.button.pointer()) {
                            if (rplanner.tool == .move) {
                                dvui.captureMouse(widget_data);
                                dvui.dragStart(mouse.p, .{});
                            }
                            // event.handle(@src(), widget_data);
                        },
                        .release => if (mouse.button.pointer()) {
                            if (rplanner.tool == .move) {
                                dvui.captureMouse(null);
                                dvui.dragEnd();
                            }
                            // event.handle(@src(), widget_data);
                        },
                        .motion => {
                            if (rplanner.tool == .move) {
                                if (dvui.dragging(mouse.p)) |p| {
                                    rplanner.camera.x -= p.x / rplanner.camera.zoom;
                                    rplanner.camera.y -= p.y / rplanner.camera.zoom;
                                }
                            }
                            // event.handle(@src(), widget_data);
                        },
                        .wheel_y => |scroll_y| {
                            const min_zoom = @min(
                                rs.r.w / BG_WIDTH_PX,
                                rs.r.h / BG_HEIGHT_PX,
                            );

                            var zoom_factor = 1.0 + @abs(scroll_y) / 100;
                            if (scroll_y < 0) {
                                zoom_factor = 1.0 / zoom_factor;
                            }

                            // rplanner.camera.zoom = std.math.clamp(rplanner.camera.zoom * zoom_factor, min_zoom, 64);
                            //
                            // rplanner.camera.x += mouse.p.x; // rplanner.camera.zoom;
                            // rplanner.camera.y += mouse.p.y; // rplanner.camera.zoom;
                            const old_zoom = rplanner.camera.zoom;
                            const new_zoom = std.math.clamp(old_zoom * zoom_factor, min_zoom, 64);

                            // Mouse position in world coords before zoom
                            const world_x = rplanner.camera.x + (mouse.p.x - rs.r.x) / old_zoom;
                            const world_y = rplanner.camera.y + (mouse.p.y - rs.r.y) / old_zoom;

                            // Apply zoom
                            rplanner.camera.zoom = new_zoom;

                            // Adjust camera so that the world point under the mouse stays fixed
                            rplanner.camera.x = world_x - (mouse.p.x - rs.r.x) / new_zoom;
                            rplanner.camera.y = world_y - (mouse.p.y - rs.r.y) / new_zoom;
                            // event.handle(@src(), widget_data);
                        },
                        .position => {
                            if (rplanner.tool == .move) {
                                dvui.cursorSet(.hand);
                            }
                            // event.handle(@src(), widget_data);
                        },
                        else => {},
                    }
                }
            },
            else => {},
        }
    }

    rplanner.camera.x = std.math.clamp(
        rplanner.camera.x,
        0,
        @max(0, BG_WIDTH_PX - (rplanner.camera.w / rplanner.camera.zoom)),
    );
    rplanner.camera.y = std.math.clamp(
        rplanner.camera.y,
        0,
        @max(0, BG_HEIGHT_PX - (rplanner.camera.h / rplanner.camera.zoom)),
    );

    // Set the render texture as the current rendering target.
    _ = sdl.SDL_SetRenderTarget(rplanner.sdl_renderer, rplanner.viewport_texture);

    // Draw the background onto the render texture.
    _ = sdl.SDL_RenderTexture(
        rplanner.sdl_renderer,
        rplanner.forest_bg_texture,
        null,
        null,
    );

    for (0..REALM_WIDTH_TILES) |x| {
        var y: usize = REALM_HEIGHT_TILES;
        while (y >= 164) : (y -= 1) {
            _ = sdl.SDL_RenderTexture(
                rplanner.sdl_renderer,
                rplanner.bedrock_texture,
                &.{
                    .x = if ((x * TILE_SIZE_PX) % 32 == 0) 0 else 16,
                    .y = if ((y * TILE_SIZE_PX) % 32 == 0) 24 else 0,
                    .h = TILE_TALL_SIZE_PC,
                    .w = TILE_SIZE_PX,
                },
                &.{
                    .x = @as(f32, @floatFromInt(TILE_SIZE_PX * x)),
                    .y = @as(f32, @floatFromInt(TILE_SIZE_PX * y)) - TILE_HEIGHT_EXTRA_PX,
                    .h = TILE_TALL_SIZE_PC,
                    .w = TILE_SIZE_PX,
                },
            );
        }
    }

    for (0..10) |tx| {
        for (0..10) |ty| {
            _ = sdl.SDL_RenderTexture(
                rplanner.sdl_renderer,
                rplanner.bedrock_texture,
                &.{
                    .x = if ((tx * TILE_SIZE_PX) % 32 == 0) 0 else 16,
                    .y = if ((ty * TILE_SIZE_PX) % 32 == 0) 24 else 0,
                    .h = TILE_TALL_SIZE_PC,
                    .w = TILE_SIZE_PX,
                },
                &.{
                    .x = @as(f32, @floatFromInt(TILE_SIZE_PX * tx)),
                    .y = @as(f32, @floatFromInt(TILE_SIZE_PX * ty)) - 8,
                    .h = TILE_TALL_SIZE_PC,
                    .w = TILE_SIZE_PX,
                },
            );
        }
    }

    if (rplanner.show_grid) {
        // Draw vertical grid lines.
        for (0..REALM_WIDTH_TILES + 1) |x| {
            _ = sdl.SDL_RenderLine(
                rplanner.sdl_renderer,
                @floatFromInt(x * TILE_SIZE_PX),
                0,
                @floatFromInt(x * TILE_SIZE_PX),
                BG_HEIGHT_PX,
            );
        }

        // Draw horizontal grid lines.
        for (0..REALM_HEIGHT_TILES + 1) |y| {
            _ = sdl.SDL_RenderLine(
                rplanner.sdl_renderer,
                0,
                @floatFromInt(y * TILE_SIZE_PX),
                BG_WIDTH_PX,
                @floatFromInt(y * TILE_SIZE_PX),
            );
        }
    }

    // Reset render target back to main window.
    _ = sdl.SDL_SetRenderTarget(rplanner.sdl_renderer, null);

    _ = sdl.SDL_RenderTexture(
        rplanner.sdl_renderer,
        rplanner.viewport_texture,
        &.{
            .x = rplanner.camera.x,
            .y = rplanner.camera.y,
            .w = rplanner.camera.w / rplanner.camera.zoom,
            .h = rplanner.camera.h / rplanner.camera.zoom,
        },
        &.{
            .x = rs.r.x,
            .y = rs.r.y,
            .w = rs.r.w,
            .h = rs.r.h,
        },
    );
}

pub fn menubar(rplanner: *Rplanner) !void {
    var menu = dvui.menu(
        @src(),
        .horizontal,
        .{
            .expand = .horizontal,
            .background = true,
            .color_fill = .{ .name = .fill },
        },
    );
    defer menu.deinit();

    if (dvui.menuItemLabel(
        @src(),
        "File",
        .{ .submenu = true },
        .{
            .expand = .none,
            .padding = .{ .x = 5, .y = 2, .w = 5, .h = 2 },
            .corner_radius = .all(0),
        },
    )) |rect| {
        var floating_menu = dvui.floatingMenu(
            @src(),
            .{ .from = rect },
            .{
                .padding = .all(0),
                .corner_radius = .all(0),
            },
        );
        defer floating_menu.deinit();

        if (floatingMenuItem(@src(), "New", null, null)) |_| {
            try rplanner.rplans.append(
                rplanner.allocator,
                .{ .filename = "test!" },
            );

            std.debug.print("capacity: {?}", .{rplanner.rplans.capacity});
            std.debug.print("len: {?}", .{rplanner.rplans.items.len});
            std.debug.print("items: {?}", .{rplanner.rplans.items[0]});
        }

        if (floatingMenuItem(@src(), "Open", null, null)) |_| {}

        if (floatingMenuItem(@src(), "Open Recent", null, null)) |_| {}

        if (floatingMenuItem(@src(), "Save", null, null)) |_| {}

        if (floatingMenuItem(@src(), "Save As", null, null)) |_| {}

        if (floatingMenuItem(@src(), "Quit", "Ctrl+Q", icons.@"log-out")) |_| {
            rplanner.running = false;
        }
    }

    if (dvui.menuItemLabel(
        @src(),
        "Edit",
        .{ .submenu = true },
        .{
            .expand = .none,
            .padding = .{ .x = 5, .y = 2, .w = 5, .h = 2 },
            .corner_radius = .all(0),
        },
    )) |rect| {
        var floating_menu = dvui.floatingMenu(
            @src(),
            .{ .from = rect },
            .{
                .padding = .all(0),
                .corner_radius = .all(0),
            },
        );
        defer floating_menu.deinit();

        if (floatingMenuItem(@src(), "Undo", "Ctrl+Z", icons.undo)) |_| {
            // TODO: undo
        }
        if (floatingMenuItem(@src(), "Redo", "Ctrl+Y", icons.redo)) |_| {
            // TODO: redo
        }
    }

    if (dvui.menuItemLabel(
        @src(),
        "View",
        .{ .submenu = true },
        .{
            .expand = .none,
            .padding = .{ .x = 5, .y = 2, .w = 5, .h = 2 },
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
        floatingMenuCheckbox(@src(), "Grid", null, &rplanner.show_grid);
        floatingMenuCheckbox(@src(), "Recent Blocks", null, &rplanner.show_recent_blocks);
        floatingMenuCheckbox(@src(), "Placed Blocks", null, &rplanner.show_placed_blocks);
        floatingMenuCheckbox(@src(), "Demo Window", null, &rplanner.show_demo);
    }

    if (dvui.menuItemLabel(
        @src(),
        "Window",
        .{ .submenu = true },
        .{
            .expand = .none,
            .padding = .{ .x = 5, .y = 2, .w = 5, .h = 2 },
            .corner_radius = .all(0),
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

pub fn tabbar(rplanner: *Rplanner) void {
    if (!rplanner.show_home_tab and
        rplanner.rplans.items.len <= 0)
    {
        return;
    }

    var tabs = dvui.TabsWidget.init(
        @src(),
        .{ .dir = .horizontal },
        .{
            .expand = .horizontal,
            .padding = .{ .y = 2 },
            .background = true,
            .color_fill = .{ .name = .fill },
        },
    );
    tabs.install();
    defer tabs.deinit();

    var home_tab = tabs.addTab(
        rplanner.selected_rplan == null,
        .{
            .padding = .{ .x = 5, .y = 3, .w = 5, .h = 3 },
            .color_fill_press = if (rplanner.selected_rplan == null) .{ .name = .fill_window } else .{ .name = .fill_hover },
            .color_fill_hover = if (rplanner.selected_rplan == null) .{ .name = .fill_window } else .{ .name = .fill_hover },
        },
    );
    defer home_tab.deinit();

    if (home_tab.clicked()) rplanner.selected_rplan = null;

    dvui.labelNoFmt(
        @src(),
        "this is the home tab.",
        .{},
        .{ .padding = .all(0) },
    );

    std.debug.print("before for loop", .{});
    for (0.., rplanner.rplans.items) |i, _| {
        var tab = tabs.addTab(
            rplanner.selected_rplan == i,
            .{
                .padding = .{ .x = 5, .y = 3, .w = 5, .h = 3 },
                .color_fill_press = if (rplanner.selected_rplan == i) .{ .name = .fill_window } else .{ .name = .fill_hover },
                .color_fill_hover = if (rplanner.selected_rplan == i) .{ .name = .fill_window } else .{ .name = .fill_hover },
            },
        );
        defer tab.deinit();

        if (tab.clicked()) rplanner.selected_rplan = i;

        var hbox = dvui.box(@src(), .horizontal, .{ .expand = .horizontal });
        defer hbox.deinit();

        std.debug.print("before access of rplan.filename", .{});
        // dvui.label(
        //     @src(),
        //     "{s}",
        //     .{rplan.filename},
        //     .{ .padding = .all(0) },
        // );
        std.debug.print("after access of rplan.filename", .{});
    }
}

fn toolbar(rplanner: *Rplanner) void {
    var hbox = dvui.box(@src(), .horizontal, .{ .expand = .horizontal });
    defer hbox.deinit();

    if (dvui.buttonIcon(@src(), "Move", icons.hand, .{}, .{}, .{})) {
        rplanner.tool = .move;
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

pub fn sidebar(_: *Rplanner) void {
    var vbox = dvui.box(@src(), .vertical, .{
        .expand = .vertical,
        .color_fill = .{ .name = .fill_window },
    });
    defer vbox.deinit();

    dvui.labelNoFmt(
        @src(),
        "hello, I am sidebar",
        .{},
        .{},
    );
}

pub fn content(rplanner: *Rplanner) void {
    var vbox = dvui.box(
        @src(),
        .vertical,
        .{
            .expand = .both,
            .color_fill = .{ .name = .fill_window },
        },
    );
    defer vbox.deinit();

    rplanner.toolbar();

    rplanner.viewport();
}

fn floatingMenuItem(src: std.builtin.SourceLocation, label_str: []const u8, shortcut_str: ?[]const u8, icon_tvg: ?[]const u8) ?dvui.Rect.Natural {
    var menu_item = dvui.menuItem(
        src,
        .{},
        .{
            .min_size_content = .width(150),
            .expand = .horizontal,
            .padding = .all(2),
            .corner_radius = .all(0),
        },
    );
    defer menu_item.deinit();

    var ret: ?dvui.Rect.Natural = null;
    if (menu_item.activeRect()) |r| {
        ret = r;
    }

    var hbox = dvui.box(
        @src(),
        .horizontal,
        .{
            .expand = .horizontal,
            .padding = .all(0),
        },
    );
    defer hbox.deinit();

    if (icon_tvg) |tvg_bytes| {
        dvui.icon(
            @src(),
            label_str,
            tvg_bytes,
            .{},
            .{
                .margin = .{ .x = 4, .w = 4 },
                .gravity_y = 0.5,
            },
        );
    } else {
        _ = dvui.spacer(
            @src(),
            .{
                .margin = .{ .x = 4, .w = 4 },
                .min_size_content = .width(dvui.themeGet().font_body.textHeight()),
            },
        );
    }

    dvui.labelNoFmt(
        @src(),
        label_str,
        .{},
        .{
            .padding = .all(0),
            .gravity_y = 0.5,
        },
    );

    if (shortcut_str) |str| {
        dvui.labelNoFmt(
            @src(),
            str,
            .{},
            .{
                .padding = .all(0),
                .margin = .{ .w = 2 },
                .gravity_x = 1.0,
                .gravity_y = 0.5,
            },
        );
    }

    return ret;
}

fn floatingMenuCheckbox(src: std.builtin.SourceLocation, label_str: []const u8, shortcut_str: ?[]const u8, target: *bool) void {
    var menu_item = dvui.menuItem(
        src,
        .{},
        .{
            .min_size_content = .width(150),
            .expand = .horizontal,
            .padding = .all(2),
            .corner_radius = .all(0),
        },
    );
    defer menu_item.deinit();

    if (menu_item.activeRect()) |_| {
        target.* = !target.*;
    }

    var hbox = dvui.box(
        @src(),
        .horizontal,
        .{
            .expand = .horizontal,
            .padding = .all(0),
        },
    );
    defer hbox.deinit();

    if (target.*) {
        dvui.icon(
            @src(),
            label_str,
            icons.check,
            .{},
            .{
                .margin = .{ .x = 4, .w = 4 },
                .gravity_y = 0.5,
            },
        );
    } else {
        _ = dvui.spacer(
            @src(),
            .{
                .margin = .{ .x = 4, .w = 4 },
                .min_size_content = .width(dvui.themeGet().font_body.textHeight()),
            },
        );
    }

    dvui.labelNoFmt(
        @src(),
        label_str,
        .{},
        .{
            .padding = .all(0),
            .gravity_y = 0.5,
        },
    );

    if (shortcut_str) |str| {
        dvui.labelNoFmt(
            @src(),
            str,
            .{},
            .{
                .padding = .all(0),
                .margin = .{ .w = 2 },
                .gravity_x = 1.0,
                .gravity_y = 0.5,
            },
        );
    }
}
