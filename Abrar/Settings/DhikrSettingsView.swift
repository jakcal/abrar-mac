import SwiftUI

struct DhikrSettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(SettingsStore.self) private var store
    @State private var newPhrase = ""

    var body: some View {
        @Bindable var store = store
        let reminders = store.settings.dhikrReminders
        Form {
            Section {
                AdhkarRow(session: .morning, isOn: $store.settings.adhkar.morning) {
                    DelayPicker(delay: $store.settings.adhkar.morningDelay, prayer: "Fajr")
                }
                AdhkarRow(session: .evening, isOn: $store.settings.adhkar.evening) {
                    DelayPicker(delay: $store.settings.adhkar.eveningDelay, prayer: "Asr")
                }
                AdhkarRow(session: .night, isOn: $store.settings.adhkar.night) {
                    TimeOfDayPicker(title: "At", minute: $store.settings.adhkar.nightTime)
                }
            } header: {
                Text("Daily Adhkar")
            } footer: {
                HStack(alignment: .firstTextBaseline) {
                    Text("Get a notification when it's time. Click it, or use the menu bar, to read along with a counter.")
                    Spacer()
                    Button("Open Adhkar") { app.showAdhkar(.morning) }
                }
            }

            Section {
                Toggle("Remind me to remember Allah", isOn: $store.settings.dhikrReminders.isEnabled)
                Group {
                    Picker("Every", selection: $store.settings.dhikrReminders.interval) {
                        ForEach(DhikrReminders.intervals, id: \.self) { Text(Self.intervalLabel($0)).tag($0) }
                    }
                    LabeledContent("Between") {
                        HStack(spacing: 6) {
                            TimeOfDayPicker(title: "From", minute: $store.settings.dhikrReminders.start)
                            Text("and").foregroundStyle(.secondary)
                            TimeOfDayPicker(title: "To", minute: $store.settings.dhikrReminders.end)
                        }
                    }
                    Picker("Sound", selection: $store.settings.dhikrReminders.sound) {
                        ForEach([AlertSound.tone, .silent]) { option in
                            Label(option.displayName, systemImage: option.symbolName).tag(option)
                        }
                    }
                }
                .disabled(!reminders.isEnabled)
            } header: {
                Text("Reminders")
            } footer: {
                reminderSummary(reminders)
            }

            Section {
                ForEach(DhikrPhrase.builtIn) { phrase in
                    Toggle(isOn: phraseBinding(phrase.id)) {
                        PhraseLabel(phrase: phrase)
                    }
                }
                ForEach($store.settings.dhikrReminders.customPhrases) { $custom in
                    Toggle(isOn: $custom.isEnabled) {
                        HStack {
                            Text(custom.text)
                            Spacer()
                            Button("Delete", systemImage: "trash") { delete(custom) }
                                .buttonStyle(.icon(size: 24))
                                .foregroundStyle(.secondary)
                                .help("Delete this phrase")
                        }
                    }
                }
                HStack {
                    TextField("Add your own", text: $newPhrase, prompt: Text("Add your own phrase, in any language"))
                        .labelsHidden()
                        .onSubmit(addPhrase)
                    Button("Add", systemImage: "plus", action: addPhrase)
                        .disabled(trimmedPhrase.isEmpty)
                }
            } header: {
                Text("Phrases")
            } footer: {
                Text("Reminders take turns through the phrases you turn on.")
            }
        }
        .formStyle(.grouped)
        .toggleStyle(.switch)
    }

    @ViewBuilder
    private func reminderSummary(_ reminders: DhikrReminders) -> some View {
        let count = DhikrPlanner.reminderMinutes(reminders).count
        if reminders.isEnabled && reminders.rotation.isEmpty {
            Label("Turn on at least one phrase below.", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        } else if count >= DhikrPlanner.maxReminders {
            Text("\(count) reminders a day, the most Abrar can schedule alongside prayer alerts. Widen the interval to spread them out.")
        } else {
            Text("\(count) reminder\(count == 1 ? "" : "s") a day.")
        }
    }

    private var trimmedPhrase: String {
        newPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addPhrase() {
        guard !trimmedPhrase.isEmpty else { return }
        store.settings.dhikrReminders.customPhrases.append(CustomDhikr(text: trimmedPhrase))
        newPhrase = ""
    }

    private func delete(_ phrase: CustomDhikr) {
        store.settings.dhikrReminders.customPhrases.removeAll { $0.id == phrase.id }
    }

    private func phraseBinding(_ id: String) -> Binding<Bool> {
        Binding(
            get: { store.settings.dhikrReminders.enabledPhrases.contains(id) },
            set: { enabled in
                if enabled {
                    store.settings.dhikrReminders.enabledPhrases.insert(id)
                } else {
                    store.settings.dhikrReminders.enabledPhrases.remove(id)
                }
            }
        )
    }

    static func intervalLabel(_ minutes: Int) -> String {
        switch minutes {
        case 60: "Hour"
        case let m where m % 60 == 0: "\(m / 60) hours"
        case let m where m > 60: "\((Double(m) / 60).formatted()) hours"
        default: "\(minutes) minutes"
        }
    }
}

private struct AdhkarRow<Timing: View>: View {
    let session: AdhkarSession
    @Binding var isOn: Bool
    @ViewBuilder var timing: Timing

    var body: some View {
        LabeledContent {
            HStack(spacing: 12) {
                timing
                    .disabled(!isOn)
                Toggle(session.title, isOn: $isOn)
                    .labelsHidden()
            }
        } label: {
            Label {
                HStack(spacing: 8) {
                    Text(session.displayName)
                    Text(session.arabicTitle)
                        .font(QuranFont.font(size: 15))
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: session.symbolName)
            }
        }
    }
}

private struct DelayPicker: View {
    @Binding var delay: Int
    let prayer: String

    var body: some View {
        Picker("Time", selection: $delay) {
            ForEach(AdhkarSettings.delays, id: \.self) { minutes in
                Text(minutes == 0 ? "At \(prayer)" : "\(minutes) min after \(prayer)").tag(minutes)
            }
        }
        .labelsHidden()
        .fixedSize()
    }
}

/// Edits a time of day stored as minutes from midnight.
private struct TimeOfDayPicker: View {
    let title: String
    @Binding var minute: Int

    var body: some View {
        DatePicker(title, selection: date, displayedComponents: .hourAndMinute)
            .labelsHidden()
            .fixedSize()
    }

    private var date: Binding<Date> {
        Binding(
            get: { Calendar.current.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: Date()) ?? Date() },
            set: { newValue in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                minute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
            }
        )
    }
}

private struct PhraseLabel: View {
    let phrase: DhikrPhrase

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(phrase.transliteration)
                Text(phrase.meaning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(phrase.arabic)
                .font(QuranFont.font(size: 17))
                .foregroundStyle(.secondary)
        }
    }
}
