import SwiftUI

/// First-run state: no place yet, so no prayer times.
struct LocationPrompt: View {
    var chooseCity: () -> Void

    @Environment(SettingsStore.self) private var store
    @Environment(LocationController.self) private var location

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: location.isLocating ? "location.circle" : "location.circle.fill")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse, isActive: location.isLocating)
            VStack(spacing: 4) {
                Text(location.isLocating ? "Finding your location…" : "Where are you praying from?")
                    .font(.headline)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .help(location.errorMessage ?? "")
            }
            VStack(spacing: 6) {
                Button { useMyLocation() } label: {
                    Label("Use My Location", systemImage: "location.fill")
                        .frame(maxWidth: .infinity)
                }
                .glassButtonStyle(prominent: true)
                .controlSize(.large)
                .disabled(location.isLocating)
                Button("Choose a City…", action: chooseCity)
                    .buttonStyle(.link)
                    .font(.callout)
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private var message: String {
        if location.errorMessage != nil, store.settings.locationMode == .automatic {
            return "Couldn't find your location. Try again, or pick a city."
        }
        return "Abrar needs your location to calculate accurate prayer times."
    }

    private func useMyLocation() {
        if store.settings.locationMode == .automatic {
            Task { await location.refresh() }
        } else {
            store.settings.locationMode = .automatic
        }
    }
}
