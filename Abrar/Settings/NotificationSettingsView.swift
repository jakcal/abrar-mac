import SwiftUI

struct NotificationSettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(SettingsStore.self) private var store

    var body: some View {
        Form {
            Section("Notify me for") {
                ForEach(PrayerName.obligatory) { prayer in
                    Toggle(prayer.displayName, isOn: binding(for: prayer))
                }
            }
            Section("Adhan") {
                Toggle("Play full adhan while Abrar is running", isOn: Bindable(store).settings.playFullAdhan)
                HStack {
                    Button("Preview", systemImage: "play.fill", action: app.playAdhan)
                    Button("Stop", systemImage: "stop.fill", action: app.stopAdhan)
                }
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
