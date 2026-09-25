import SwiftUI

struct NotificationSettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(SettingsStore.self) private var store

    var body: some View {
        Form {
            Section {
                ForEach(PrayerName.obligatory) { prayer in
                    Toggle(isOn: binding(for: prayer)) {
                        Label(prayer.displayName, systemImage: prayer.symbolName)
                    }
                }
            } header: {
                Text("Notify Me For")
            } footer: {
                Text("Notifications arrive at the start of each prayer, even when the menu is closed.")
            }
            Section {
                Toggle("Play the full adhan", isOn: Bindable(store).settings.playFullAdhan)
                LabeledContent("Preview") {
                    HStack {
                        Button("Play", systemImage: "play.fill", action: app.playAdhan)
                        Button("Stop", systemImage: "stop.fill", action: app.stopAdhan)
                    }
                }
            } header: {
                Text("Adhan")
            } footer: {
                Text("Plays while Abrar is running and pauses any recitation.")
            }
            #if DEBUG
            Section("Debug") {
                Button("Fire Test Notification in 5 s", action: app.fireTestNotification)
            }
            #endif
        }
        .formStyle(.grouped)
    }

    private func binding(for prayer: PrayerName) -> Binding<Bool> {
        Binding(
            get: { store.settings.notifiedPrayers.contains(prayer) },
            set: { enabled in
                if enabled {
                    store.settings.notifiedPrayers.insert(prayer)
                } else {
                    store.settings.notifiedPrayers.remove(prayer)
                }
            }
        )
    }
}
