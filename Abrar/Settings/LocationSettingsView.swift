import SwiftUI

struct LocationSettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(SettingsStore.self) private var store
    @Environment(LocationController.self) private var location
    @State private var query = ""

    var body: some View {
        @Bindable var store = store
        Form {
            Picker("Location", selection: $store.settings.locationMode) {
                Text("Automatic").tag(LocationMode.automatic)
                Text("Choose a city").tag(LocationMode.manual)
            }
            .pickerStyle(.segmented)

            switch store.settings.locationMode {
            case .automatic: automatic
            case .manual: manual
            }
        }
        .formStyle(.grouped)
    }

    private var automatic: some View {
        Section {
            LabeledContent("Current", value: store.settings.detectedPlace?.displayName ?? "Unknown")
            if let error = location.errorMessage {
                Text(error).foregroundStyle(.red).font(.callout)
            }
            HStack {
                Button("Update Location") { Task { await location.refresh() } }
                    .disabled(location.isLocating)
                if location.isLocating { ProgressView().controlSize(.small) }
            }
        }
    }

    private var manual: some View {
        Section {
            LabeledContent("Selected", value: store.settings.manualPlace?.displayName ?? "None")
            TextField("Search cities", text: $query)
            List(app.services.cities.search(query)) { place in
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
            }
            .frame(minHeight: 200)
        }
    }
}
