const std = @import("std");
const rl = @import("raylib");

const map_mod = @import("map.zig");
const player_mod = @import("player.zig");
const collision_mod = @import("collision.zig");
const raycaster_mod = @import("raycaster.zig");
const menu_mod = @import("menu.zig");

const Map = map_mod.Map;
const Player = player_mod.Player;
const Menu = menu_mod.Menu;
const MenuAction = menu_mod.MenuAction;

pub const GameState = enum {
    menu,
    playing,
    finished,
};

pub const Game = struct {
    state: GameState,
    map: Map,
    player: Player,
    title_menu: Menu,
    finish_menu: Menu,
    timer_start: f64,
    finish_time: f64,
    timer_running: bool,
    should_quit: bool,
    fps_display: i32,
    fps_update_timer: f32,

    const MOVE_SPEED: f32 = 2.5;
    const ROT_SPEED: f32 = 2.0;
    const FPS_UPDATE_INTERVAL: f32 = 0.25;

    pub fn init(allocator: std.mem.Allocator) !Game {
        const title_buttons = [_][:0]const u8{ "Comenzar", "Salir" };
        const finish_buttons = [_][:0]const u8{ "Volver a jugar", "Cerrar" };

        return .{
            .state = .menu,
            .map = try Map.init(allocator),
            .player = Player.init(0, 0, 0),
            .title_menu = Menu.init(&title_buttons),
            .finish_menu = Menu.init(&finish_buttons),
            .timer_start = 0,
            .finish_time = 0,
            .timer_running = false,
            .should_quit = false,
            .fps_display = raycaster_mod.TARGET_FPS,
            .fps_update_timer = 0,
        };
    }

    pub fn deinit(self: *Game) void {
        self.map.deinit();
    }

    pub fn startGame(self: *Game) void {
        self.player.reset(self.map.spawn_x, self.map.spawn_y, self.map.spawn_angle);
        self.timer_start = rl.getTime();
        self.finish_time = 0;
        self.timer_running = true;
        self.state = .playing;
    }

    fn resetToMenu(self: *Game) void {
        self.state = .menu;
        self.title_menu.selected = 0;
        self.timer_running = false;
    }

    pub fn update(self: *Game) void {
        const dt = rl.getFrameTime();

        switch (self.state) {
            .menu => self.updateMenu(),
            .playing => self.updatePlaying(dt),
            .finished => self.updateFinished(),
        }
    }

    fn updateMenu(self: *Game) void {
        switch (self.title_menu.update()) {
            .confirm => switch (self.title_menu.selected) {
                0 => self.startGame(),
                1 => self.should_quit = true,
                else => {},
            },
            .back => self.should_quit = true,
            .none => {},
        }
    }

    fn updatePlaying(self: *Game, dt: f32) void {
        if (rl.isKeyPressed(.escape)) {
            self.resetToMenu();
            return;
        }

        if (rl.isKeyDown(.w)) {
            const new_x = self.player.x + @cos(self.player.angle) * MOVE_SPEED * dt;
            const new_y = self.player.y + @sin(self.player.angle) * MOVE_SPEED * dt;
            collision_mod.tryMove(&self.map, &self.player, new_x, new_y);
        }
        if (rl.isKeyDown(.s)) {
            const new_x = self.player.x - @cos(self.player.angle) * MOVE_SPEED * dt;
            const new_y = self.player.y - @sin(self.player.angle) * MOVE_SPEED * dt;
            collision_mod.tryMove(&self.map, &self.player, new_x, new_y);
        }
        if (rl.isKeyDown(.a)) {
            self.player.rotate(-ROT_SPEED * dt);
        }
        if (rl.isKeyDown(.d)) {
            self.player.rotate(ROT_SPEED * dt);
        }

        if (collision_mod.reachedExit(&self.map, &self.player)) {
            self.finish_time = rl.getTime() - self.timer_start;
            self.timer_running = false;
            self.finish_menu.selected = 0;
            self.state = .finished;
        }

        self.fps_update_timer += dt;
        if (self.fps_update_timer >= FPS_UPDATE_INTERVAL) {
            self.fps_display = rl.getFPS();
            self.fps_update_timer = 0;
        }
    }

    fn updateFinished(self: *Game) void {
        switch (self.finish_menu.update()) {
            .confirm => switch (self.finish_menu.selected) {
                0 => self.startGame(),
                1 => self.should_quit = true,
                else => {},
            },
            .back => self.resetToMenu(),
            .none => {},
        }
    }

    pub fn draw(self: *const Game) void {
        switch (self.state) {
            .menu => self.title_menu.draw(
                "Laberinth",
                null,
                raycaster_mod.SCREEN_WIDTH,
                raycaster_mod.SCREEN_HEIGHT,
            ),
            .playing => self.drawPlaying(),
            .finished => {
                var time_buf: [32]u8 = undefined;
                const time_text = menu_mod.formatTimeZ(&time_buf, self.finish_time);
                self.finish_menu.draw(
                    "FINISH",
                    time_text,
                    raycaster_mod.SCREEN_WIDTH,
                    raycaster_mod.SCREEN_HEIGHT,
                );
            },
        }
    }

    fn drawPlaying(self: *const Game) void {
        raycaster_mod.render(&self.map, self.player.x, self.player.y, self.player.angle);

        var fps_buf: [24]u8 = undefined;
        const written = std.fmt.bufPrint(&fps_buf, "FPS: {d}", .{self.fps_display}) catch {
            rl.drawText("FPS: --", 10, 10, 20, .white);
            return;
        };
        fps_buf[written.len] = 0;
        rl.drawText(fps_buf[0..written.len :0], 10, 10, 20, .white);
    }
};
