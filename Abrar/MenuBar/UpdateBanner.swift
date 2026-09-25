import SwiftUI

struct UpdateBanner: View {
    let release: AppRelease
    var download: () -> Void

    var body: some View {
        Button(action: download) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.down.app.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Abrar \(release.version.description) is available")
                        .font(.callout.weight(.semibold))
                    Text("Click to download")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassCard(tint: .accentColor)
        .accessibilityLabel("Abrar \(release.version.description) is available. Download.")
    }
}
