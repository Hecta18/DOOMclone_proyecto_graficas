const std = @import("std");
const rl = @import("raylib");

const map_mod = @import("map.zig");

const Map = map_mod.Map;
const CellType = map_mod.CellType;

pub const SCREEN_WIDTH: i32 = 1366;
pub const SCREEN_HEIGHT: i32 = 768;
pub const TARGET_FPS: i32 = 15;
pub const FOV: f32 = std.math.pi / 3.0;
pub const MAX_DISTANCE: f32 = 20.0;

const floor_color = rl.Color{ .r = 80, .g = 50, .b = 30, .a = 255 };
const ceiling_color = rl.Color{ .r = 70, .g = 90, .b = 110, .a = 255 };

const RayHit = struct {
    distance: f32,
    wall_type: CellType,
};

fn castRay(m: *const Map, pos_x: f32, pos_y: f32, dir_x: f32, dir_y: f32) RayHit {
    var map_x: i32 = @intFromFloat(pos_x);
    var map_y: i32 = @intFromFloat(pos_y);

    const delta_dist_x: f32 = if (dir_x == 0) std.math.floatMax(f32) else @abs(1.0 / dir_x);
    const delta_dist_y: f32 = if (dir_y == 0) std.math.floatMax(f32) else @abs(1.0 / dir_y);

    var step_x: i32 = undefined;
    var step_y: i32 = undefined;
    var side_dist_x: f32 = undefined;
    var side_dist_y: f32 = undefined;

    if (dir_x < 0) {
        step_x = -1;
        side_dist_x = (pos_x - @as(f32, @floatFromInt(map_x))) * delta_dist_x;
    } else {
        step_x = 1;
        side_dist_x = (@as(f32, @floatFromInt(map_x)) + 1.0 - pos_x) * delta_dist_x;
    }

    if (dir_y < 0) {
        step_y = -1;
        side_dist_y = (pos_y - @as(f32, @floatFromInt(map_y))) * delta_dist_y;
    } else {
        step_y = 1;
        side_dist_y = (@as(f32, @floatFromInt(map_y)) + 1.0 - pos_y) * delta_dist_y;
    }

    var side: i32 = 0;
    var hit = false;
    var wall_type: CellType = .wall_normal;

    while (!hit) {
        if (side_dist_x < side_dist_y) {
            side_dist_x += delta_dist_x;
            map_x += step_x;
            side = 0;
        } else {
            side_dist_y += delta_dist_y;
            map_y += step_y;
            side = 1;
        }

        if (!m.inBounds(map_x, map_y)) {
            wall_type = .wall_normal;
            hit = true;
            break;
        }

        wall_type = m.get(map_x, map_y);
        if (m.isWall(map_x, map_y)) {
            hit = true;
        }
    }

    var perp_dist: f32 = undefined;
    if (side == 0) {
        perp_dist = side_dist_x - delta_dist_x;
    } else {
        perp_dist = side_dist_y - delta_dist_y;
    }

    if (perp_dist < 0.001) perp_dist = 0.001;
    if (perp_dist > MAX_DISTANCE) perp_dist = MAX_DISTANCE;

    return .{ .distance = perp_dist, .wall_type = wall_type };
}

pub fn render(m: *const Map, pos_x: f32, pos_y: f32, angle: f32) void {
    const half_height = @divTrunc(SCREEN_HEIGHT, 2);

    rl.drawRectangle(0, 0, SCREEN_WIDTH, half_height, ceiling_color);
    rl.drawRectangle(0, half_height, SCREEN_WIDTH, half_height, floor_color);

    var x: i32 = 0;
    while (x < SCREEN_WIDTH) : (x += 1) {
        const ray_angle = angle - FOV / 2.0 +
            (@as(f32, @floatFromInt(x)) / @as(f32, @floatFromInt(SCREEN_WIDTH))) * FOV;
        const ray_dir_x = @cos(ray_angle);
        const ray_dir_y = @sin(ray_angle);

        const hit = castRay(m, pos_x, pos_y, ray_dir_x, ray_dir_y);

        const line_height: i32 = @intFromFloat(@min(
            @as(f32, @floatFromInt(SCREEN_HEIGHT)),
            @as(f32, @floatFromInt(SCREEN_HEIGHT)) / hit.distance,
        ));

        const draw_start = @max(0, half_height - @divTrunc(line_height, 2));
        const draw_end = @min(SCREEN_HEIGHT, half_height + @divTrunc(line_height, 2));

        const rgb = Map.wallColor(hit.wall_type);
        const color = rl.Color{ .r = rgb.r, .g = rgb.g, .b = rgb.b, .a = 255 };

        rl.drawLine(x, draw_start, x, draw_end, color);
    }
}
