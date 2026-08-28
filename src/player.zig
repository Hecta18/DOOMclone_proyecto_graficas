pub const Player = struct {
    x: f32,
    y: f32,
    angle: f32,

    pub fn init(x: f32, y: f32, angle: f32) Player {
        return .{ .x = x, .y = y, .angle = angle };
    }

    pub fn reset(self: *Player, x: f32, y: f32, angle: f32) void {
        self.x = x;
        self.y = y;
        self.angle = angle;
    }

    pub fn rotate(self: *Player, delta: f32) void {
        self.angle += delta;
    }

    pub fn moveForward(self: *Player, distance: f32) void {
        self.x += @cos(self.angle) * distance;
        self.y += @sin(self.angle) * distance;
    }

    pub fn moveBackward(self: *Player, distance: f32) void {
        self.x -= @cos(self.angle) * distance;
        self.y -= @sin(self.angle) * distance;
    }
};
