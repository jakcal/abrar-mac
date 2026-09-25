import SwiftUI

struct LocationSettingsView: View {
    @Environment(SettingsStore.self) private var store

    var body: some View {
        @Bindable var store = store
        Form {
            Section {
                Picker("Find location", selection: $store.settings.locationMode) {
                    Text("Automatically").tag(LocationMode.automatic)
                    Text("Choose a City").tag(LocationMode.manual)
                }
                .pickerStyle(.segmented)
            } footer: {
                Text("Prayer times are calculated for this place, in its time zone.")
            }

            switch store.settings.locationMode {
            case .automatic: AutomaticLocationSection()
            case .manual: CityPickerSection()
            }
        }
        .formStyle(.grouped)
    }
}

private struct AutomaticLocationSection: View {
    @Environment(SettingsStore.self) private var store
    @Environment(LocationController.self) private var location

    var body: some View {
        Section {
            LabeledContent("Current location") {
                Text(store.settings.detectedPlace?.displayName ?? "Not found yet")
                    .foregroundStyle(store.settings.detectedPlace == nil ? .secondary : .primary)
            }
            if let error = location.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.callout)
            }
            HStack {
                Button("Update Location", systemImage: "location") { Task { await location.refresh() } }
                    .disabled(location.isLocating)
                if location.isLocating {
                    ProgressView().controlSize(.small)
                    Text("Locating…").foregroundStyle(.secondary)
                }
            }
        } footer: {
            Text("Updated each time Abrar launches. If macOS denies access, choose a city instead.")
        }
    }
}

private struct CityPickerSection: View {
    @Environment(AppModel.self) private var app
    @Environment(SettingsStore.self) private var store
    @State private var query = ""

    var body: some View {
        let results = app.services.cities.search(query)
        Section {
            LabeledContent("Selected city", value: store.settings.manualPlace?.displayName ?? "None")
            TextField("Search", text: $query, prompt: Text("City or country"))
        }
        Section {
            if results.isEmpty {
                Text("No cities match “\(query)”.")
                    .foregroundStyle(.secondary)
            }
            ForEach(results) { place in
                Button {
                    store.settings.manualPlace = place
                } label: {
                    HStack {
                        Text(place.name)
                        Text(place.country).foregroundStyle(.secondary)
                        Spacer()
                        if place == store.settings.manualPlace {
                            Image(systemName: "checkmark").foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(place == store.settings.manualPlace ? .isSelected : [])
            }
        }
    }
}
