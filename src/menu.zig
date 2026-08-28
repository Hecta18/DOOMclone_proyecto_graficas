const std = @import("std");
const rl = @import("raylib");

pub const MenuAction = enum {
    none,
    confirm,
    back,
};

pub const Menu = struct {
    buttons: []const [:0]const u8,
    selected: usize,

    pub fn init(buttons: []const [:0]const u8) Menu {
        return .{ .buttons = buttons, .selected = 0 };
    }

    pub fn update(self: *Menu) MenuAction {
        if (rl.isKeyPressed(.up) or rl.isKeyPressed(.w)) {
            if (self.selected > 0) self.selected -= 1;
        }
        if (rl.isKeyPressed(.down) or rl.isKeyPressed(.s)) {
            if (self.selected + 1 < self.buttons.len) self.selected += 1;
        }
        if (rl.isKeyPressed(.enter) or rl.isKeyPressed(.kp_enter)) {
            return .confirm;
        }
        if (rl.isKeyPressed(.escape)) {
            return .back;
        }
        return .none;
    }

    pub fn draw(self: *const Menu, title: [:0]const u8, subtitle: ?[:0]const u8, screen_w: i32, screen_h: i32) void {
        const bg = rl.Color{ .r = 20, .g = 20, .b = 30, .a = 255 };
        rl.clearBackground(bg);

        const title_size: i32 = 48;
        const title_w = rl.measureText(title, title_size);
        rl.drawText(title, @divTrunc(screen_w - title_w, 2), @divTrunc(screen_h, 6), title_size, .white);

        if (subtitle) |sub| {
            const sub_size: i32 = 24;
            const sub_w = rl.measureText(sub, sub_size);
            rl.drawText(sub, @divTrunc(screen_w - sub_w, 2), @divTrunc(screen_h, 6) + 60, sub_size, .white);
        }

        const button_y_start = if (subtitle != null) @divTrunc(screen_h, 2) + 20 else @divTrunc(screen_h, 2);
        const button_spacing: i32 = 50;
        const font_size: i32 = 28;

        for (self.buttons, 0..) |label, i| {
            const y = button_y_start + @as(i32, @intCast(i)) * button_spacing;
            const text_w = rl.measureText(label, font_size);
            const x = @divTrunc(screen_w - text_w, 2);

            const color: rl.Color = if (i == self.selected)
                rl.Color{ .r = 255, .g = 220, .b = 50, .a = 255 }
            else
                .white;

            if (i == self.selected) {
                const pad: i32 = 12;
                rl.drawRectangle(x - pad, y - @divTrunc(pad, 2), text_w + pad * 2, font_size + pad, rl.Color{
                    .r = 80,
                    .g = 70,
                    .b = 20,
                    .a = 180,
                });
            }

            rl.drawText(label, x, y, font_size, color);
        }
    }
};

pub fn formatTime(buf: []u8, seconds: f64) []const u8 {
    const mins = @as(u32, @intFromFloat(@floor(seconds / 60.0)));
    const secs = seconds - @as(f64, @floatFromInt(mins)) * 60.0;
    return std.fmt.bufPrint(buf, "Tiempo: {d:0>2}:{d:05.2}", .{ mins, secs }) catch "Tiempo: 00:00.00";
}

pub fn formatTimeZ(buf: []u8, seconds: f64) [:0]const u8 {
    const written = formatTime(buf, seconds);
    buf[written.len] = 0;
    return buf[0..written.len :0];
}
