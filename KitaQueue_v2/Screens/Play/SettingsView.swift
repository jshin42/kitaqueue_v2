import SwiftUI

struct SettingsView: View {
    @State private var settings = PersistenceService.shared.loadSettings()

    var body: some View {
        List {
            Section("Audio & Feedback") {
                Toggle("Sound Effects", isOn: $settings.soundEnabled)
                Toggle("Music", isOn: $settings.musicEnabled)
                Toggle("Haptics", isOn: $settings.hapticsEnabled)
            }

            Section("Accessibility") {
                Toggle("Reduce Motion", isOn: $settings.reduceMotion)
                Toggle("High Contrast Ghost", isOn: $settings.highContrastGhost)
            }

            Section("Purchases") {
                Button("Restore Purchases") {
                    // Will be implemented in M12
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .onChange(of: settings) { _, newValue in
            PersistenceService.shared.saveSettings(newValue)
        }
    }
}
