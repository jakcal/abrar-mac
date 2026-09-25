import SwiftUI

struct NotificationSettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(SettingsStore.self) private var store

    var body: some View {
        Form {
            Section {
                ForEach(PrayerName.obligatory) { prayer in
                    PrayerAlertRow(prayer: prayer, isOn: binding(for: prayer), sound: soundBinding(for: prayer))
                }
            } header: {
                Text("Notify Me For")
            } footer: {
                Text("Notifications arrive at the start of each prayer, even when the menu is closed. Silent shows the banner without a sound.")
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
                Text("Plays for prayers set to Adhan while Abrar is running, and pauses any recitation.")
            }
            #if DEBUG
            Section("Debug") {
                Button("Fire Test Notification in 5 s", action: app.fireTestNotification)
            }
            #endif
        }
        .formStyle(.grouped)
    }

    private func soundBinding(for prayer: PrayerName) -> Binding<AlertSound> {
        Binding(
            get: { store.settings.prayerSounds[prayer] },
            set: { store.settings.prayerSounds[prayer] = $0 }
        )
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

private struct PrayerAlertRow: View {
    let prayer: PrayerName
    @Binding var isOn: Bool
    @Binding var sound: AlertSound

    var body: some View {
        LabeledContent {
            HStack(spacing: 12) {
                Picker("Sound", selection: $sound) {
                    ForEach(AlertSound.allCases) { option in
                        Label(option.displayName, systemImage: option.symbolName).tag(option)
                    }
                }
                .labelsHidden()
                .fixedSize()
                .disabled(!isOn)
                Toggle("Notify", isOn: $isOn)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }
        } label: {
            Label(prayer.displayName, systemImage: prayer.symbolName)
        }
    }
}
