const dvui = @import("dvui");

pub const Theme: dvui.Theme = .{
    .name = "Rplanner Dark",
    .dark = true,
    .alpha = 1.0,
    .color_accent = .{ .r = 96, .g = 165, .b = 250, .a = 255 }, // Blue-400 (brighter for dark)
    .color_err = .{ .r = 248, .g = 113, .b = 113, .a = 255 }, // Red-400 (brighter for dark)
    .color_text = .{ .r = 243, .g = 244, .b = 246, .a = 255 }, // Gray-100
    .color_text_press = .{ .r = 229, .g = 231, .b = 235, .a = 255 }, // Gray-200
    .color_fill = .{ .r = 17, .g = 24, .b = 39, .a = 255 }, // Gray-900
    .color_fill_window = .{ .r = 31, .g = 41, .b = 55, .a = 255 }, // Gray-800
    .color_fill_control = .{ .r = 55, .g = 65, .b = 81, .a = 255 }, // Gray-700
    .color_fill_hover = .{ .r = 75, .g = 85, .b = 99, .a = 255 }, // Gray-600
    .color_fill_press = .{ .r = 107, .g = 114, .b = 128, .a = 255 }, // Gray-500
    .color_border = .{ .r = 75, .g = 85, .b = 99, .a = 255 }, // Gray-600
    .font_body = .{ .name = "Lato", .size = 14 },
    .font_heading = .{ .name = "Lato", .size = 14 },
    .font_caption = .{ .name = "Lato", .size = 11 }, // 14 * 0.77 = 10.78 ≈ 11
    .font_caption_heading = .{ .name = "Lato", .size = 11 }, // 14 * 0.77 = 10.78 ≈ 11
    .font_title = .{ .name = "Lato", .size = 30 }, // 14 * 2.15 = 30.1 ≈ 30
    .font_title_1 = .{ .name = "Lato", .size = 25 }, // 14 * 1.77 = 24.78 ≈ 25
    .font_title_2 = .{ .name = "Lato", .size = 22 }, // 14 * 1.54 = 21.56 ≈ 22
    .font_title_3 = .{ .name = "Lato", .size = 18 }, // 14 * 1.3 = 18.2 ≈ 18
    .font_title_4 = .{ .name = "Lato", .size = 16 }, // 14 * 1.15 = 16.1 ≈ 16
    .style_accent = .{},
    .style_err = .{},
    .allocated_strings = false,
};
