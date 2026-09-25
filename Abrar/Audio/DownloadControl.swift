import SwiftUI

struct DownloadControl: View {
    let surah: Surah
    let reciter: Reciter

    @Environment(DownloadManager.self) private var downloads

    private var key: DownloadKey { DownloadKey(reciterID: reciter.id, surah: surah.id) }

    var body: some View {
        switch downloads.state(for: key) {
        case .notDownloaded:
            downloadButton("Download", systemImage: "arrow.down.circle")
                .help("Save for offline listening")
        case let .failed(message):
            downloadButton("Retry Download", systemImage: "exclamationmark.arrow.circlepath")
                .help("Download failed: \(message)")
        case let .downloading(fraction):
            Button { downloads.cancel(key) } label: {
                HStack(spacing: 8) {
                    ProgressView(value: fraction)
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                    Text(fraction.formatted(.percent.precision(.fractionLength(0))))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }
            .glassButtonStyle()
            .help("Downloading… click to cancel")
            .accessibilityLabel("Downloading, \(Int(fraction * 100)) percent. Cancel download")
        case let .downloaded(size):
            Menu {
                Text("Saved for offline listening · \(size.formatted(.byteCount(style: .file)))")
                Button("Delete Download", systemImage: "trash", role: .destructive) { downloads.delete(key) }
            } label: {
                Label("Downloaded", systemImage: "checkmark.circle.fill")
            }
            .menuStyle(.button)
            .glassButtonStyle()
            .fixedSize()
            .help("Available offline")
        }
    }

    private func downloadButton(_ title: String, systemImage: String) -> some View {
        Button(title, systemImage: systemImage) {
            guard let url = reciter.remoteURL(forSurah: surah.id) else { return }
            downloads.download(key, from: url)
        }
        .glassButtonStyle()
    }
}
