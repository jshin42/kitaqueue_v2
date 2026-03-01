import AVFoundation

/// Manages sound effects and music playback.
/// SFX: system sounds as placeholders (replace with bundled audio when available).
/// Music: loops gameplay/menu tracks when present in bundle; silence otherwise.
@MainActor
final class SoundManager {
    static let shared = SoundManager()

    var isSoundEnabled: Bool = true
    var isMusicEnabled: Bool = true

    private var musicPlayer: AVAudioPlayer?
    private var currentMusicTrack: String?

    private init() {
        // Configure audio session for game (mix with other audio)
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

    // MARK: - Music

    func startGameplayMusic() {
        playMusic(named: "gameplay_loop")
    }

    func startMenuMusic() {
        playMusic(named: "menu_loop")
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
        currentMusicTrack = nil
    }

    func updateMusicEnabled(_ enabled: Bool) {
        isMusicEnabled = enabled
        if !enabled {
            stopMusic()
        }
    }

    private func playMusic(named name: String) {
        guard isMusicEnabled else { return }
        guard currentMusicTrack != name else { return } // Already playing

        stopMusic()

        // Try to load from Sounds/ directory in bundle
        guard let url = Bundle.main.url(forResource: name, withExtension: "m4a", subdirectory: "Sounds")
                ?? Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Sounds")
                ?? Bundle.main.url(forResource: name, withExtension: "m4a")
                ?? Bundle.main.url(forResource: name, withExtension: "mp3")
        else {
            // No music file available — silent placeholder
            currentMusicTrack = name
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1 // Loop forever
            player.volume = 0.3
            player.prepareToPlay()
            player.play()
            musicPlayer = player
            currentMusicTrack = name
        } catch {
            currentMusicTrack = name
        }
    }
}
