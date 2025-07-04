const Rplan = @This();

const std = @import("std");

pub const Camera = struct {
    x: f32 = 0,
    y: f32 = 0,
    w: f32 = 0,
    h: f32 = 0,
    zoom: f32 = 1.0,
};

const REALM_WIDTH_TILES = 300;
const REALM_HEIGHT_TILES = 170;

const Viewport = struct {
    camera: Camera,
};

const TileKind = enum {
    default,
    big,
};

const Tile = struct {
    name: []const u8,
    kind: TileKind,
};

filename: []const u8,
// viewport: Viewport,
// tilemap: [REALM_WIDTH_TILES][REALM_HEIGHT_TILES]Tile,

pub fn new() !void {
    var file = try std.fs.cwd().createFile("untitled.rplan", .{});
    defer file.close();
}

pub fn open(filename: []const u8) void {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
}

pub fn save() void {}
pub fn saveAs() void {}
