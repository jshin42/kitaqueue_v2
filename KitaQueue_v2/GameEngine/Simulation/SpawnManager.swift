import Foundation

/// Manages wave spawning: 6 waves x 4 shuriken, 0.6s spacing, 1.2s breath.
struct SpawnManager: Sendable {
    private let levelData: LevelData

    init(levelData: LevelData) {
        self.levelData = levelData
    }

    /// Determines if a new shuriken should spawn this tick.
    /// Returns the shuriken to spawn, or nil.
    func shouldSpawn(state: GameState, dt: Double) -> (lane: Int, color: ShurikenColor)? {
        guard state.phase == .playing else { return nil }
        guard state.currentWave < levelData.waves.count else { return nil }

        let wave = levelData.waves[state.currentWave]
        guard state.shurikenInCurrentWave < wave.count else { return nil }

        // Check timing
        if state.waveBreathing {
            // In breath window between waves
            if state.breathElapsed >= GameConstants.breathWindowDuration {
                // Breath done, spawn first of next wave
                let entry = wave[state.shurikenInCurrentWave]
                return (entry.lane, entry.color)
            }
            return nil
        }

        if state.shurikenInCurrentWave == 0 && state.currentWave == 0 {
            // First spawn ever - spawn immediately after preview ends
            let entry = wave[0]
            return (entry.lane, entry.color)
        }

        if state.timeSinceLastSpawn >= GameConstants.interShurikenSpacing {
            let entry = wave[state.shurikenInCurrentWave]
            return (entry.lane, entry.color)
        }

        return nil
    }

    /// Get the upcoming shuriken colors for the spawn preview strip
    func spawnPreview(state: GameState, count: Int) -> [ShurikenColor] {
        var preview: [ShurikenColor] = []
        var waveIdx = state.currentWave
        var entryIdx = state.shurikenInCurrentWave

        while preview.count < count && waveIdx < levelData.waves.count {
            let wave = levelData.waves[waveIdx]
            if entryIdx < wave.count {
                preview.append(wave[entryIdx].color)
                entryIdx += 1
            } else {
                waveIdx += 1
                entryIdx = 0
            }
        }
        return preview
    }
}
