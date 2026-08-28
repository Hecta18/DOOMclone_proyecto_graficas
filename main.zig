const std = @import("std");
const rl = @import("raylib");

const game_mod = @import("game.zig");
const raycaster_mod = @import("raycaster.zig");
const audio_mod = @import("audio.zig");

pub fn main() !void {
    rl.initWindow(raycaster_mod.SCREEN_WIDTH, raycaster_mod.SCREEN_HEIGHT, "Laberinth");
    defer rl.closeWindow();

    rl.setTargetFPS(raycaster_mod.TARGET_FPS);

    var game = try game_mod.Game.init(std.heap.page_allocator);
    defer game.deinit();

    var audio = audio_mod.Audio.init();
    audio.load("resources/music.ogg");
    defer audio.deinit();

    while (!rl.windowShouldClose() and !game.should_quit) {
        game.update();
        audio.update();

        rl.beginDrawing();
        defer rl.endDrawing();

        game.draw();
    }
}
