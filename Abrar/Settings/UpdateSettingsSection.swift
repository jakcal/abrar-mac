import SwiftUI

struct UpdateSettingsSection: View {
    @Environment(SettingsStore.self) private var store
    @Environment(UpdateController.self) private var updates

    var body: some View {
        Section {
            Toggle("Check for updates automatically", isOn: Bindable(store).settings.checkForUpdates)
            if let release = updates.available {
                LabeledContent {
                    HStack {
                        Button("Release Notes", action: updates.openReleaseNotes)
                        Button("Download", action: updates.download)
                            .glassButtonStyle(prominent: true)
                    }
                } label: {
                    Label("Abrar \(release.version.description) is available", systemImage: "arrow.down.app.fill")
                }
            } else {
                LabeledContent {
                    Button("Check Now") { Task { await updates.check() } }
                        .disabled(updates.status == .checking)
                } label: {
                    statusLabel
                }
            }
        } header: {
            Text("Updates")
        } footer: {
            Text("Abrar checks GitHub for new releases once a day. Download the new version and replace the app in Applications.")
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch updates.status {
        case .checking:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Checking…")
            }
        case .failed:
            Label("Couldn't check for updates", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        case .upToDate:
            Text("Abrar is up to date")
        case .idle:
            Text("Not checked yet")
                .foregroundStyle(.secondary)
        }
    }
}
