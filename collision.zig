const map_mod = @import("map.zig");
const player_mod = @import("player.zig");

const Map = map_mod.Map;
const Player = player_mod.Player;

pub const PLAYER_RADIUS: f32 = 0.2;

const check_offsets = [_][2]f32{
    .{ 0, 0 },
    .{ PLAYER_RADIUS, 0 },
    .{ -PLAYER_RADIUS, 0 },
    .{ 0, PLAYER_RADIUS },
    .{ 0, -PLAYER_RADIUS },
};

pub fn wouldCollide(m: *const Map, x: f32, y: f32) bool {
    for (check_offsets) |offset| {
        const px = x + offset[0];
        const py = y + offset[1];
        const mx = @as(i32, @intFromFloat(px));
        const my = @as(i32, @intFromFloat(py));
        if (m.isWall(mx, my)) return true;
    }
    return false;
}

pub fn tryMove(m: *const Map, p: *Player, new_x: f32, new_y: f32) void {
    if (!wouldCollide(m, new_x, p.y)) {
        p.x = new_x;
    }
    if (!wouldCollide(m, p.x, new_y)) {
        p.y = new_y;
    }
}

pub fn reachedExit(m: *const Map, p: *const Player) bool {
    const dx = p.x - m.exit_x;
    const dy = p.y - m.exit_y;
    const dist_sq = dx * dx + dy * dy;
    return dist_sq < 0.25;
}
