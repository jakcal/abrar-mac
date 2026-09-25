import SwiftUI

/// "Download all surahs" for the selected reciter: idle, running and complete states.
struct DownloadAllView: View {
    /// Compact is the glass card in the Quran sidebar; otherwise a Settings form row.
    var compact = false

    @Environment(SettingsStore.self) private var store
    @Environment(DownloadManager.self) private var downloads
    @State private var confirmsDelete = false

    private var reciter: Reciter { Reciter.with(id: store.settings.reciterID) }

    var body: some View {
        let progress = downloads.bulkProgress(reciterID: reciter.id)
        if compact && progress.isComplete {
            EmptyView()
        } else if compact {
            // A plain fill: the sidebar is already a glass pane on macOS 26.
            content(progress)
                .padding(12)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(10)
        } else {
            content(progress)
        }
    }

    private func content(_ progress: BulkDownloadProgress) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: symbol(progress))
                    .font(.title3)
                    .foregroundStyle(progress.isComplete ? AnyShapeStyle(.green) : AnyShapeStyle(.tint))
                    .contentTransition(.symbolEffect(.replace))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title(progress))
                        .font(compact ? .callout.weight(.medium) : .body)
                    Text(subtitle(progress))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                Spacer(minLength: 4)
                action(progress)
            }
            if progress.isRunning {
                ProgressView(value: progress.fraction)
                    .progressViewStyle(.linear)
                    .controlSize(.small)
                    .accessibilityLabel("Download progress")
            }
        }
        .motion(Motion.standard, value: progress.isRunning)
        .confirmationDialog(
            "Delete all \(progress.savedCount) downloaded surahs for \(reciter.name)?",
            isPresented: $confirmsDelete
        ) {
            Button("Delete All", role: .destructive) { downloads.deleteAll(reciterID: reciter.id) }
        } message: {
            Text("This frees \(progress.savedBytes.formatted(.byteCount(style: .file))). You can download them again at any time.")
        }
    }

    @ViewBuilder
    private func action(_ progress: BulkDownloadProgress) -> some View {
        if progress.isRunning {
            Button("Stop") { downloads.cancelAll(reciterID: reciter.id) }
                .controlSize(compact ? .small : .regular)
        } else if progress.isComplete {
            Button("Delete All…", role: .destructive) { confirmsDelete = true }
        } else {
            Button(progress.failedCount > 0 ? "Retry" : "Download") { downloads.downloadAll(reciter: reciter) }
                .glassButtonStyle(prominent: !compact)
                .controlSize(compact ? .small : .regular)
        }
    }

    private func symbol(_ progress: BulkDownloadProgress) -> String {
        if progress.isComplete { return "checkmark.circle.fill" }
        return progress.isRunning ? "arrow.down.circle.dotted" : "arrow.down.circle"
    }

    private func title(_ progress: BulkDownloadProgress) -> String {
        if progress.isComplete { return "All 114 surahs downloaded" }
        return progress.isRunning ? "Downloading all surahs" : "Download all surahs"
    }

    private func subtitle(_ progress: BulkDownloadProgress) -> String {
        let total = BulkDownloadProgress.surahCount
        if progress.isComplete {
            return "\(progress.savedBytes.formatted(.byteCount(style: .file))) · \(reciter.name)"
        }
        if progress.isRunning {
            return "\(progress.savedCount) of \(total) · \(progress.fraction.formatted(.percent.precision(.fractionLength(0))))"
        }
        var text = progress.savedCount == 0
            ? "Save all \(total) for offline listening"
            : "\(progress.remaining) remaining · \(progress.savedCount)/\(total) saved"
        if progress.failedCount > 0 {
            text += " · \(progress.failedCount) failed"
        }
        return text
    }
}
