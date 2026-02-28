import Foundation

enum LevelLoader {
    /// Load a level by ID from the bundle
    static func load(id: Int) -> LevelData? {
        let filename = String(format: "level_%03d", id)

        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            return nil
        }

        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(LevelData.self, from: data)
    }

    /// Load a level or generate a placeholder for levels beyond authored content
    static func loadOrGenerate(id: Int) -> LevelData {
        if let level = load(id: id) {
            return level
        }

        // Generate a template level for ids beyond authored content
        return generateLevel(id: id)
    }

    /// Generate a simple template level
    private static func generateLevel(id: Int) -> LevelData {
        // All shuriken pre-aligned (auto-win without operators)
        let wave: [LevelData.WaveEntry] = (0..<4).map { lane in
            LevelData.WaveEntry(lane: lane, color: ShurikenColor.bankColor(for: lane))
        }
        let waves = Array(repeating: wave, count: 6)

        return LevelData(
            id: id,
            waves: waves,
            gates: [],
            threeStarMaxOps: 6,
            twoStarMaxOps: 8
        )
    }
}
