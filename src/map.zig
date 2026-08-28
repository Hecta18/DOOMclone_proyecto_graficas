const std = @import("std");

pub const CellType = enum {
    empty,
    wall_normal,
    wall_start,
    wall_exit,
};

pub const Map = struct {
    width: usize,
    height: usize,
    cells: []CellType,
    spawn_x: f32,
    spawn_y: f32,
    spawn_angle: f32,
    exit_x: f32,
    exit_y: f32,
    allocator: std.mem.Allocator,

    const map_ascii =
        \\####################
        \\#S   B#            #
        \\# ### # ######## # #
        \\# #   # #      # # #
        \\# # ### ###### # # #
        \\# #            # # #
        \\# ############## # #
        \\#                # #
        \\# #### ######## ## #
        \\# #  #        #  # #
        \\# # ## ###### # ## #
        \\# #  #      # #  # #
        \\# ####  ##  ### ## #
        \\#      #  #     G E#
        \\####################
    ;

    pub fn init(allocator: std.mem.Allocator) !Map {
        var lines = std.mem.splitScalar(u8, map_ascii, '\n');
        var height: usize = 0;
        var width: usize = 0;

        while (lines.next()) |line| {
            if (line.len == 0) continue;
            height += 1;
            width = @max(width, line.len);
        }

        const cells = try allocator.alloc(CellType, width * height);
        @memset(cells, .wall_normal);

        var spawn_x: f32 = 1.5;
        var spawn_y: f32 = 1.5;
        var spawn_angle: f32 = 0;
        var exit_x: f32 = 0;
        var exit_y: f32 = 0;

        lines = std.mem.splitScalar(u8, map_ascii, '\n');
        var y: usize = 0;
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            for (line, 0..) |ch, x| {
                const cell = parseCell(ch);
                cells[y * width + x] = cell;
                switch (ch) {
                    'S' => {
                        spawn_x = @as(f32, @floatFromInt(x)) + 0.5;
                        spawn_y = @as(f32, @floatFromInt(y)) + 0.5;
                        spawn_angle = 0;
                    },
                    'E' => {
                        exit_x = @as(f32, @floatFromInt(x)) + 0.5;
                        exit_y = @as(f32, @floatFromInt(y)) + 0.5;
                    },
                    else => {},
                }
            }
            y += 1;
        }

        return .{
            .width = width,
            .height = height,
            .cells = cells,
            .spawn_x = spawn_x,
            .spawn_y = spawn_y,
            .spawn_angle = spawn_angle,
            .exit_x = exit_x,
            .exit_y = exit_y,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Map) void {
        self.allocator.free(self.cells);
    }

    fn parseCell(ch: u8) CellType {
        return switch (ch) {
            '#' => .wall_normal,
            'B' => .wall_start,
            'G' => .wall_exit,
            'S', 'E', ' ' => .empty,
            else => .empty,
        };
    }

    pub fn inBounds(self: *const Map, x: i32, y: i32) bool {
        return x >= 0 and y >= 0 and
            @as(usize, @intCast(x)) < self.width and
            @as(usize, @intCast(y)) < self.height;
    }

    pub fn get(self: *const Map, x: i32, y: i32) CellType {
        if (!self.inBounds(x, y)) return .wall_normal;
        return self.cells[@as(usize, @intCast(y)) * self.width + @as(usize, @intCast(x))];
    }

    pub fn isWall(self: *const Map, x: i32, y: i32) bool {
        return switch (self.get(x, y)) {
            .wall_normal, .wall_start, .wall_exit => true,
            .empty => false,
        };
    }

    pub fn wallColor(cell: CellType) struct { r: u8, g: u8, b: u8 } {
        return switch (cell) {
            .wall_normal => .{ .r = 64, .g = 64, .b = 64 },
            .wall_start => .{ .r = 50, .g = 100, .b = 200 },
            .wall_exit => .{ .r = 50, .g = 180, .b = 80 },
            .empty => .{ .r = 64, .g = 64, .b = 64 },
        };
    }
};
