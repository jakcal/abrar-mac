import SwiftUI

struct DownloadControl: View {
    let surah: Surah
    let reciter: Reciter

    @Environment(DownloadManager.self) private var downloads

    private var key: DownloadKey { DownloadKey(reciterID: reciter.id, surah: surah.id) }

    var body: some View {
        switch downloads.state(for: key) {
        case .notDownloaded:
            downloadButton("Download")
        case let .failed(message):
            downloadButton("Retry Download")
                .help(message)
        case let .downloading(fraction):
            HStack(spacing: 8) {
                ProgressView(value: fraction)
                    .frame(width: 80)
                Button("Cancel", systemImage: "xmark.circle.fill") { downloads.cancel(key) }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
            }
        case let .downloaded(size):
            Menu {
                Button("Delete Download", systemImage: "trash", role: .destructive) { downloads.delete(key) }
            } label: {
                Label(
                    "Downloaded · \(size.formatted(.byteCount(style: .file)))",
                    systemImage: "checkmark.circle.fill"
                )
            }
            .fixedSize()
        }
    }

    private func downloadButton(_ title: String) -> some View {
        Button(title, systemImage: "arrow.down.circle") {
            guard let url = reciter.remoteURL(forSurah: surah.id) else { return }
            downloads.download(key, from: url)
        }
    }
}
