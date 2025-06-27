const dvui = @import("dvui");

pub const Theme: dvui.Theme = .{
    .name = "Rplanner Light",
    .dark = false,
    .alpha = 1.0,
    .color_accent = .{ .r = 59, .g = 130, .b = 246, .a = 255 }, // Blue-500
    .color_err = .{ .r = 239, .g = 68, .b = 68, .a = 255 }, // Red-500
    .color_text = .{ .r = 31, .g = 41, .b = 55, .a = 255 }, // Gray-800
    .color_text_press = .{ .r = 55, .g = 65, .b = 81, .a = 255 }, // Gray-700
    .color_fill = .{ .r = 249, .g = 250, .b = 251, .a = 255 }, // Gray-50
    .color_fill_window = .{ .r = 243, .g = 244, .b = 246, .a = 255 }, // Gray-100
    .color_fill_control = .{ .r = 229, .g = 231, .b = 235, .a = 255 }, // Gray-200
    .color_fill_hover = .{ .r = 209, .g = 213, .b = 219, .a = 255 }, // Gray-300
    .color_fill_press = .{ .r = 156, .g = 163, .b = 175, .a = 255 }, // Gray-400
    .color_border = .{ .r = 209, .g = 213, .b = 219, .a = 255 }, // Gray-300
    .font_body = .{ .name = "Lato", .size = 14 },
    .font_heading = .{ .name = "Lato", .size = 18 },
    .font_caption = .{ .name = "Lato", .size = 12 },
    .font_caption_heading = .{ .name = "Lato", .size = 13 },
    .font_title = .{ .name = "Lato", .size = 24 },
    .font_title_1 = .{ .name = "Lato", .size = 32 },
    .font_title_2 = .{ .name = "Lato", .size = 28 },
    .font_title_3 = .{ .name = "Lato", .size = 22 },
    .font_title_4 = .{ .name = "Lato", .size = 20 },
    .style_accent = .{},
    .style_err = .{},
    .allocated_strings = false,
};
