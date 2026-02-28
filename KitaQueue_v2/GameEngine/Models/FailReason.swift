import Foundation

enum FailReason: Hashable, Sendable {
    case misbank(shurikenColor: ShurikenColor, bankLane: Int)
    case overflow(lane: Int)
}
