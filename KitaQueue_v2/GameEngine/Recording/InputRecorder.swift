import Foundation

/// Records player inputs during a level for determinism verification and replay.
final class InputRecorder {
    private(set) var inputs: [PlayerInput] = []

    func record(_ input: PlayerInput) {
        inputs.append(input)
    }

    func clear() {
        inputs.removeAll()
    }

    func encode() -> Data? {
        try? JSONEncoder().encode(inputs)
    }
}
