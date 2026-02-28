import Foundation

struct UserSettings: Codable, Equatable {
    var soundEnabled: Bool = true
    var musicEnabled: Bool = true
    var hapticsEnabled: Bool = true
    var reduceMotion: Bool = false
    var highContrastGhost: Bool = false
    var adsRemoved: Bool = false
}
