import Foundation

/// Lightweight telemetry logger.
/// DEBUG: writes JSON lines to Documents/telemetry.jsonl
/// RELEASE: no-op (can be hooked to analytics SDK later)
final class TelemetryService: @unchecked Sendable {
    static let shared = TelemetryService()

    // MARK: - Context

    private let sessionId: String
    private var levelId: Int = 0
    private var attemptId: Int = 0

    // MARK: - File Handle

    private let queue = DispatchQueue(label: "com.kitaqueue.telemetry")
    private var fileHandle: FileHandle?
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }()

    private init() {
        sessionId = UUID().uuidString

        #if DEBUG
        openLogFile()
        #endif
    }

    // MARK: - Context Updates

    func setLevel(_ id: Int, attempt: Int) {
        queue.async { [self] in
            levelId = id
            attemptId = attempt
        }
    }

    // MARK: - Log

    func log(_ event: TelemetryEvent) {
        #if DEBUG
        queue.async { [self] in
            writeEvent(event)
        }
        #endif
    }

    // MARK: - Private

    private func openLogFile() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("telemetry.jsonl")

        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }

        fileHandle = try? FileHandle(forWritingTo: url)
        fileHandle?.seekToEndOfFile()
    }

    private func writeEvent(_ event: TelemetryEvent) {
        guard let handle = fileHandle else { return }

        // Build wrapper with context
        let wrapper = EventWrapper(
            timestamp: ISO8601DateFormatter().string(from: Date()),
            sessionId: sessionId,
            levelId: levelId,
            attemptId: attemptId,
            payload: event
        )

        guard let data = try? encoder.encode(wrapper) else { return }
        handle.write(data)
        handle.write(Data("\n".utf8))
    }
}

// MARK: - Event Wrapper

private struct EventWrapper: Encodable {
    let timestamp: String
    let sessionId: String
    let levelId: Int
    let attemptId: Int
    let payload: TelemetryEvent

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(levelId, forKey: .levelId)
        try container.encode(attemptId, forKey: .attemptId)
        // Flatten payload into same level
        try payload.encode(to: encoder)
    }

    enum CodingKeys: String, CodingKey {
        case timestamp, sessionId, levelId, attemptId
    }
}
