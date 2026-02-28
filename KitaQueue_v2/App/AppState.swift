import SwiftUI

@Observable
final class AppState {
    enum Tab: Int, CaseIterable {
        case play, daily, shop
    }

    enum NavigationDestination: Hashable {
        case gameplay(levelId: Int)
        case settings
    }

    var selectedTab: Tab = .play
    var navigationPath: [NavigationDestination] = []
    var currentLevel: Int = 1

    // Session counters (reset on app launch)
    var sessionWinCount: Int = 0
    var sessionFailCount: Int = 0
    var sessionFixItCount: Int = 0
}
