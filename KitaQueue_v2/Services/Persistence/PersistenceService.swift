import Foundation

final class PersistenceService: @unchecked Sendable {
    static let shared = PersistenceService()

    private let queue = DispatchQueue(label: "com.kitaqueue.persistence")

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private init() {}

    // MARK: - Progression

    func loadProgression() -> PlayerProgression {
        load(from: "progression.json") ?? PlayerProgression()
    }

    func saveProgression(_ progression: PlayerProgression) {
        save(progression, to: "progression.json")
    }

    // MARK: - Settings

    func loadSettings() -> UserSettings {
        load(from: "settings.json") ?? UserSettings()
    }

    func saveSettings(_ settings: UserSettings) {
        save(settings, to: "settings.json")
    }

    // MARK: - Daily State

    func loadDailyState() -> DailyStateModel {
        load(from: "daily_state.json") ?? DailyStateModel()
    }

    func saveDailyState(_ state: DailyStateModel) {
        save(state, to: "daily_state.json")
    }

    // MARK: - Private

    private func load<T: Decodable>(from filename: String) -> T? {
        let url = documentsURL.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func save<T: Encodable>(_ value: T, to filename: String) {
        queue.async { [documentsURL] in
            let url = documentsURL.appendingPathComponent(filename)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            guard let data = try? encoder.encode(value) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }
}
