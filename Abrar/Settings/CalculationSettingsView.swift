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
                Picker("Asr time", selection: $store.settings.madhab) {
                    ForEach(MadhabOption.allCases) { Text($0.displayName).tag($0) }
                }
            } footer: {
                Text("Use the method your local mosque follows. Hanafi places Asr later in the afternoon.")
            }
            Section {
                AngleOverrideRow(title: "Custom Fajr angle", value: $store.settings.fajrAngleOverride)
                AngleOverrideRow(title: "Custom Isha angle", value: $store.settings.ishaAngleOverride)
            } header: {
                Text("Twilight Angles")
            } footer: {
                Text("Overrides the method's sun angle below the horizon. Leave off unless you need it.")
            }
            Section {
                ForEach(PrayerName.allCases) { prayer in
                    Stepper(value: $store.settings.offsets[prayer], in: -30...30) {
                        LabeledContent(prayer.displayName, value: Self.signed(store.settings.offsets[prayer]))
                            .monospacedDigit()
                    }
                }
            } header: {
                Text("Adjustments")
            } footer: {
                Text("Shift individual times by up to 30 minutes to match your mosque's timetable.")
            }
        }
        .formStyle(.grouped)
    }

    private static func signed(_ minutes: Int) -> String {
        switch minutes {
        case 0: "On time"
        case 1...: "+\(minutes) min"
        default: "\(minutes) min"
        }
    }
}

private struct AngleOverrideRow: View {
    let title: String
    @Binding var value: Double?

    var body: some View {
        Toggle(title, isOn: Binding(
            get: { value != nil },
            set: { value = $0 ? 18 : nil }
        ))
        if let angle = value {
            Stepper(value: Binding(get: { angle }, set: { value = $0 }), in: 10...22, step: 0.5) {
                LabeledContent("Angle", value: angle.formatted(.number.precision(.fractionLength(1))) + "°")
                    .monospacedDigit()
            }
            .padding(.leading, 12)
        }
    }
}
