import SwiftUI

struct CalculationSettingsView: View {
    @Environment(SettingsStore.self) private var store

    var body: some View {
        @Bindable var store = store
        Form {
            Section {
                Picker("Method", selection: $store.settings.method) {
                    ForEach(CalculationMethodOption.allCases) { Text($0.displayName).tag($0) }
                }
                Picker("Asr", selection: $store.settings.madhab) {
                    ForEach(MadhabOption.allCases) { Text($0.displayName).tag($0) }
                }
            }
            Section("Angle overrides") {
                AngleOverrideRow(title: "Fajr angle", value: $store.settings.fajrAngleOverride)
                AngleOverrideRow(title: "Isha angle", value: $store.settings.ishaAngleOverride)
            }
            Section("Adjustments (minutes)") {
                ForEach(PrayerName.allCases) { prayer in
                    Stepper(value: $store.settings.offsets[prayer], in: -30...30) {
                        LabeledContent(prayer.displayName, value: Self.signed(store.settings.offsets[prayer]))
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private static func signed(_ minutes: Int) -> String {
        minutes > 0 ? "+\(minutes)" : "\(minutes)"
    }
}

private struct AngleOverrideRow: View {
    let title: String
    @Binding var value: Double?

    var body: some View {
        HStack {
            Toggle(title, isOn: Binding(
                get: { value != nil },
                set: { value = $0 ? 18 : nil }
            ))
            Spacer()
            if let angle = value {
                Stepper(
                    value: Binding(get: { angle }, set: { value = $0 }),
                    in: 10...22,
                    step: 0.5
                ) {
                    Text(angle.formatted(.number.precision(.fractionLength(1))) + "°")
                        .monospacedDigit()
                }
            }
        }
    }
}
