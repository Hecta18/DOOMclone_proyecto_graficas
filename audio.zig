const rl = @import("raylib");

pub const Audio = struct {
    music: rl.Music,
    loaded: bool,

    pub fn init() Audio {
        return .{
            .music = undefined,
            .loaded = false,
        };
    }

    pub fn load(self: *Audio, path: [:0]const u8) void {
        rl.initAudioDevice();
        self.music = rl.loadMusicStream(path) catch {
            self.loaded = false;
            return;
        };
        self.loaded = true;
        rl.setMusicVolume(self.music, 0.6);
        rl.playMusicStream(self.music);
    }

    pub fn update(self: *Audio) void {
        if (!self.loaded) return;
        rl.updateMusicStream(self.music);
    }

    pub fn deinit(self: *Audio) void {
        if (!self.loaded) return;
        rl.stopMusicStream(self.music);
        rl.unloadMusicStream(self.music);
        rl.closeAudioDevice();
        self.loaded = false;
    }
};
