import UIKit
import CoreHaptics

/// Manages haptic feedback for game events. Respects user settings.
@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private var engine: CHHapticEngine?
    private var isSupported: Bool = false

    var isEnabled: Bool = true

    private init() {
        isSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        if isSupported {
            prepareEngine()
        }
    }

    private func prepareEngine() {
        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            try engine?.start()
        } catch {
            isSupported = false
        }
    }

    // MARK: - Game Events

    func snapConfirm() {
        guard isEnabled else { return }
        playImpact(.medium)
    }

    func error() {
        guard isEnabled else { return }
        playNotification(.error)
    }

    func bankTick() {
        guard isEnabled else { return }
        playImpact(.light)
    }

    func winBurst() {
        guard isEnabled else { return }
        playNotification(.success)
    }

    func failThud() {
        guard isEnabled else { return }
        playNotification(.error)
    }

    func operatorTrigger() {
        guard isEnabled else { return }
        playImpact(.rigid)
    }

    // MARK: - Private

    private func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    private func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
