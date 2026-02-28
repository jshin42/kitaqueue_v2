import SwiftUI

@main
struct KitaQueueApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootTabView(appState: appState)
                .preferredColorScheme(.dark)
        }
    }
}
