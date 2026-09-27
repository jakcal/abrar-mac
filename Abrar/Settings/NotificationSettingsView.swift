import SwiftUI
import UniformTypeIdentifiers

struct NotificationSettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(SettingsStore.self) private var store
    @State private var isImporting = false
    @State private var importError: String?

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
                LabeledContent("Voice") {
                    HStack {
                        Picker("Voice", selection: Bindable(store).settings.adhanVoiceID) {
                            ForEach(store.settings.adhanVoices) { Text($0.name).tag($0.id) }
                        }
                        .labelsHidden()
                        .fixedSize()
                        if store.settings.adhanVoice.isCustom {
                            Button("Remove", systemImage: "trash") { app.removeAdhan(id: store.settings.adhanVoiceID) }
                                .buttonStyle(.icon(size: 24))
                                .foregroundStyle(.secondary)
                                .help("Remove this recording")
                        }
                        Button("Add Your Own…") { isImporting = true }
                    }
                }
                LabeledContent("Test") {
                    HStack {
                        Button("Play", systemImage: "play.fill", action: app.playAdhan)
                        Button("Stop", systemImage: "stop.fill", action: app.stopAdhan)
                    }
                }
                Toggle("Play the full adhan", isOn: Bindable(store).settings.playFullAdhan)
            } header: {
                Text("Adhan")
            } footer: {
                Text("Notifications play the first 28 seconds. The full adhan plays for prayers set to Adhan while Abrar is running, and pauses any recitation.")
            }
            #if DEBUG
            Section("Debug") {
                Button("Fire Test Notification in 5 s", action: app.fireTestNotification)
            }
            #endif
        }
        .formStyle(.grouped)
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.audio]) { result in
            guard case let .success(url) = result else { return }
            Task {
                do {
                    try await app.importAdhan(from: url)
                } catch {
                    importError = error.localizedDescription
                }
            }
        }
        .alert("Couldn't Add Recording", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importError ?? "")
        }
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
