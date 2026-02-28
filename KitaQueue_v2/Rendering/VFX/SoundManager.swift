import AVFoundation

/// Manages sound effects and music playback. Uses system sounds as placeholders.
@MainActor
final class SoundManager {
    static let shared = SoundManager()

    var isSoundEnabled: Bool = true
    var isMusicEnabled: Bool = true

    private var musicPlayer: AVAudioPlayer?

    private init() {
        // Configure audio session for game
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    // MARK: - SFX (placeholder system sounds)

    func playSlashPlace() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1104) // Tock
    }

    func playSlashTrigger() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1057) // Short click
    }

    func playGateBlock() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1073) // Low buzz
    }

    func playPaintConvert() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1117) // Pop
    }

    func playBankTick() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1105) // Tick
    }

    func playCoinTick() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1105) // Tick
    }

    func playWinSting() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1025) // Fanfare-like
    }

    func playFailThud() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1521) // Vibrate-thud
    }

    func playButtonTap() {
        guard isSoundEnabled else { return }
        AudioServicesPlaySystemSound(1104) // Tock
    }

    // MARK: - Music (placeholder: no-op until M15)

    func startGameplayMusic() {
        guard isMusicEnabled else { return }
        // Will load music/gameplay_loop.m4a in M15
    }

    func startMenuMusic() {
        guard isMusicEnabled else { return }
        // Will load music/menu_loop.m4a in M15
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }
}
