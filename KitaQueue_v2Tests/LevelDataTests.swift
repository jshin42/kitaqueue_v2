import Testing
import Foundation
@testable import KitaQueue_v2

@Suite("Level Data Tests")
struct LevelDataTests {

    // MARK: - Helpers

    /// Load level JSON directly from bundle (bypasses fallback generation)
    private func loadLevelJSON(id: Int) -> LevelData? {
        let filename = String(format: "level_%03d", id)
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            return nil
        }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(LevelData.self, from: data)
    }

    // MARK: - Load & Parse Tests

    @Test("Level 1 loads and parses", .tags(.ftue))
    func level1Loads() {
        let level = LevelLoader.loadOrGenerate(id: 1)
        #expect(level.id == 1)
    }

    @Test("Level 2 loads and parses", .tags(.ftue))
    func level2Loads() {
        let level = LevelLoader.loadOrGenerate(id: 2)
        #expect(level.id == 2)
    }

    @Test("Level 3 loads and parses", .tags(.ftue))
    func level3Loads() {
        let level = LevelLoader.loadOrGenerate(id: 3)
        #expect(level.id == 3)
    }

    @Test("Level 4 loads and parses", .tags(.ftue))
    func level4Loads() {
        let level = LevelLoader.loadOrGenerate(id: 4)
        #expect(level.id == 4)
    }

    @Test("Level 5 loads and parses", .tags(.ftue))
    func level5Loads() {
        let level = LevelLoader.loadOrGenerate(id: 5)
        #expect(level.id == 5)
    }

    @Test("Levels 6-10 load via loadOrGenerate (generated if no JSON)")
    func levels6Through10Load() {
        for id in 6...10 {
            let level = LevelLoader.loadOrGenerate(id: id)
            #expect(level.id == id, "Level \(id) should have matching id")
        }
    }

    // MARK: - Wave Structure Tests

    @Test("All levels 1-10 have exactly 6 waves")
    func allLevelsHave6Waves() {
        for id in 1...10 {
            let level = LevelLoader.loadOrGenerate(id: id)
            #expect(
                level.waves.count == GameConstants.wavesPerLevel,
                "Level \(id) should have \(GameConstants.wavesPerLevel) waves, got \(level.waves.count)"
            )
        }
    }

    @Test("All levels 1-10 have 4 entries per wave")
    func allWavesHave4Entries() {
        for id in 1...10 {
            let level = LevelLoader.loadOrGenerate(id: id)
            for (waveIndex, wave) in level.waves.enumerated() {
                #expect(
                    wave.count == GameConstants.shurikenPerWave,
                    "Level \(id) wave \(waveIndex) should have \(GameConstants.shurikenPerWave) entries, got \(wave.count)"
                )
            }
        }
    }

    @Test("All levels 1-10 have exactly 24 total shuriken")
    func totalShurikenIs24() {
        for id in 1...10 {
            let level = LevelLoader.loadOrGenerate(id: id)
            #expect(
                level.totalShuriken == GameConstants.shurikenPerLevel,
                "Level \(id) should have \(GameConstants.shurikenPerLevel) total shuriken, got \(level.totalShuriken)"
            )
        }
    }

    // MARK: - Wave Entry Validation

    @Test("All wave entries have valid lane indices (0-3)")
    func waveLanesAreValid() {
        for id in 1...10 {
            let level = LevelLoader.loadOrGenerate(id: id)
            for (waveIndex, wave) in level.waves.enumerated() {
                for (entryIndex, entry) in wave.enumerated() {
                    #expect(
                        entry.lane >= 0 && entry.lane < GameConstants.laneCount,
                        "Level \(id) wave \(waveIndex) entry \(entryIndex): lane \(entry.lane) out of range 0..<\(GameConstants.laneCount)"
                    )
                }
            }
        }
    }

    @Test("All wave entries have valid shuriken colors")
    func waveColorsAreValid() {
        let validColors = Set(ShurikenColor.allCases)
        for id in 1...10 {
            let level = LevelLoader.loadOrGenerate(id: id)
            for (waveIndex, wave) in level.waves.enumerated() {
                for (entryIndex, entry) in wave.enumerated() {
                    #expect(
                        validColors.contains(entry.color),
                        "Level \(id) wave \(waveIndex) entry \(entryIndex): invalid color \(entry.color)"
                    )
                }
            }
        }
    }

    // MARK: - Gate Validation

    @Test("All gate lanes are in valid range (0-3)")
    func gateLanesAreValid() {
        for id in 1...10 {
            let level = LevelLoader.loadOrGenerate(id: id)
            for (gateIndex, gate) in level.gates.enumerated() {
                #expect(
                    gate.lane >= 0 && gate.lane < GameConstants.laneCount,
                    "Level \(id) gate \(gateIndex): lane \(gate.lane) out of range 0..<\(GameConstants.laneCount)"
                )
            }
        }
    }

    @Test("All gate rows are in valid range (1-12)")
    func gateRowsAreValid() {
        for id in 1...10 {
            let level = LevelLoader.loadOrGenerate(id: id)
            for (gateIndex, gate) in level.gates.enumerated() {
                #expect(
                    gate.row >= 1 && gate.row <= GameConstants.rowCount,
                    "Level \(id) gate \(gateIndex): row \(gate.row) out of range 1...\(GameConstants.rowCount)"
                )
            }
        }
    }

    @Test("Color gates have a valid allowedColor")
    func colorGateParams() {
        for id in 1...10 {
            let level = LevelLoader.loadOrGenerate(id: id)
            let colorGates = level.gates.filter { $0.type == .color }
            for gate in colorGates {
                #expect(
                    gate.allowedColor != nil,
                    "Level \(id): color gate at lane \(gate.lane) row \(gate.row) is missing allowedColor"
                )
            }
        }
    }

    @Test("Toggle gates have a valid non-empty colorCycle")
    func toggleGateParams() {
        for id in 1...10 {
            let level = LevelLoader.loadOrGenerate(id: id)
            let toggleGates = level.gates.filter { $0.type == .toggle }
            for gate in toggleGates {
                #expect(
                    gate.colorCycle != nil && !(gate.colorCycle?.isEmpty ?? true),
                    "Level \(id): toggle gate at lane \(gate.lane) row \(gate.row) has nil or empty colorCycle"
                )
            }
        }
    }

    @Test("Paint gates have valid fromColor and toColor")
    func paintGateParams() {
        for id in 1...10 {
            let level = LevelLoader.loadOrGenerate(id: id)
            let paintGates = level.gates.filter { $0.type == .paint }
            for gate in paintGates {
                #expect(
                    gate.fromColor != nil,
                    "Level \(id): paint gate at lane \(gate.lane) row \(gate.row) is missing fromColor"
                )
                #expect(
                    gate.toColor != nil,
                    "Level \(id): paint gate at lane \(gate.lane) row \(gate.row) is missing toColor"
                )
                if let from = gate.fromColor, let to = gate.toColor {
                    #expect(
                        from != to,
                        "Level \(id): paint gate at lane \(gate.lane) row \(gate.row) converts \(from) to itself"
                    )
                }
            }
        }
    }

    @Test("No duplicate gates at same lane+row position")
    func noDuplicateGatePositions() {
        for id in 1...10 {
            let level = LevelLoader.loadOrGenerate(id: id)
            var seen = Set<String>()
            for gate in level.gates {
                let key = "\(gate.lane)_\(gate.row)"
                #expect(
                    !seen.contains(key),
                    "Level \(id): duplicate gate at lane \(gate.lane) row \(gate.row)"
                )
                seen.insert(key)
            }
        }
    }

    // MARK: - Star Thresholds

    @Test("Star thresholds are valid and ordered")
    func starThresholdsValid() {
        for id in 1...10 {
            let level = LevelLoader.loadOrGenerate(id: id)
            #expect(
                level.threeStarMaxOps > 0,
                "Level \(id): threeStarMaxOps must be positive"
            )
            #expect(
                level.twoStarMaxOps > 0,
                "Level \(id): twoStarMaxOps must be positive"
            )
            #expect(
                level.threeStarMaxOps <= level.twoStarMaxOps,
                "Level \(id): threeStarMaxOps (\(level.threeStarMaxOps)) should be <= twoStarMaxOps (\(level.twoStarMaxOps))"
            )
        }
    }

    // MARK: - FTUE-Specific Tests

    @Test("Level 1 has no gates (auto-win tutorial)")
    func level1NoGates() {
        let level = LevelLoader.loadOrGenerate(id: 1)
        #expect(level.gates.isEmpty, "Level 1 (FTUE: Banking) should have no gates")
    }

    @Test("Level 1 has all shuriken pre-aligned to correct banks")
    func level1AllAligned() {
        let level = LevelLoader.loadOrGenerate(id: 1)
        for wave in level.waves {
            for entry in wave {
                let expected = ShurikenColor.bankColor(for: entry.lane)
                #expect(
                    entry.color == expected,
                    "Level 1: shuriken in lane \(entry.lane) should be \(expected), got \(entry.color)"
                )
            }
        }
    }

    @Test("Level 2 has a color gate blocking red in lane 1")
    func level2HasColorGate() {
        let level = LevelLoader.loadOrGenerate(id: 2)
        let colorGatesLane1 = level.gates.filter { $0.type == .color && $0.lane == 1 }
        #expect(!colorGatesLane1.isEmpty, "Level 2 should have a color gate in lane 1")
        if let gate = colorGatesLane1.first {
            #expect(gate.allowedColor == .green, "Level 2 color gate in lane 1 should allow green")
        }
    }

    @Test("Level 4 has a paint gate")
    func level4HasPaintGate() {
        let level = LevelLoader.loadOrGenerate(id: 4)
        let paintGates = level.gates.filter { $0.type == .paint }
        #expect(!paintGates.isEmpty, "Level 4 (FTUE: Paint Gate) should have a paint gate")
    }

    @Test("Level 5 has a color gate to teach overflow")
    func level5HasColorGate() {
        let level = LevelLoader.loadOrGenerate(id: 5)
        let colorGates = level.gates.filter { $0.type == .color }
        #expect(!colorGates.isEmpty, "Level 5 (FTUE: Overflow) should have a color gate")
    }

    @Test("FTUE levels 1-5 have tutorial configs")
    func ftueLevelsTutorialConfigs() {
        for id in 1...5 {
            let level = LevelLoader.loadOrGenerate(id: id)
            #expect(
                level.tutorialConfig != nil,
                "FTUE level \(id) should have a tutorialConfig"
            )
            if let config = level.tutorialConfig {
                #expect(!config.overlayText.isEmpty, "FTUE level \(id) overlayText should not be empty")
                #expect(!config.endCardText.isEmpty, "FTUE level \(id) endCardText should not be empty")
            }
        }
    }

    // MARK: - JSON Round-Trip

    @Test("Level data survives JSON encode-decode round trip")
    func jsonRoundTrip() throws {
        let level = LevelLoader.loadOrGenerate(id: 1)
        let encoder = JSONEncoder()
        let data = try encoder.encode(level)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LevelData.self, from: data)

        #expect(decoded.id == level.id)
        #expect(decoded.waves.count == level.waves.count)
        #expect(decoded.gates.count == level.gates.count)
        #expect(decoded.threeStarMaxOps == level.threeStarMaxOps)
        #expect(decoded.twoStarMaxOps == level.twoStarMaxOps)
        #expect(decoded.totalShuriken == level.totalShuriken)
    }
}

// MARK: - Tags

extension Tag {
    @Tag static var ftue: Self
}
