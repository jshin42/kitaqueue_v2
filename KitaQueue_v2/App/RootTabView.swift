import SwiftUI

struct RootTabView: View {
    @Bindable var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack(path: $appState.navigationPath) {
                PlayHubView(appState: appState)
                    .navigationDestination(for: AppState.NavigationDestination.self) { dest in
                        switch dest {
                        case .settings:
                            SettingsView()
                        case .gameplay:
                            // Placeholder — replaced in M2 with GameplayContainerView
                            Text("Gameplay")
                        }
                    }
            }
            .tabItem {
                Label("Play", systemImage: "play.fill")
            }
            .tag(AppState.Tab.play)

            DailyView()
                .tabItem {
                    Label("Daily", systemImage: "calendar")
                }
                .tag(AppState.Tab.daily)

            ShopView()
                .tabItem {
                    Label("Shop", systemImage: "bag.fill")
                }
                .tag(AppState.Tab.shop)
        }
        .tint(.orange)
    }
}
