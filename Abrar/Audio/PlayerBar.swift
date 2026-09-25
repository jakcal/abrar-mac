import SwiftUI

/// Floating glass player under the reader. Sits in the layout, never over the text.
struct PlayerBar: View {
    let surah: Surah

    @Environment(AudioPlayerService.self) private var player
    @Environment(ReaderModel.self) private var reader

    var body: some View {
        HStack(spacing: 16) {
            PlayerTransport(isLastSurah: surah.id >= 114)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    nowPlaying
                    Spacer(minLength: 8)
                    SpeedMenu()
                    SleepTimerMenu()
                }
                PlayerScrubber()
                if let error = player.errorMessage {
                    errorRow(error)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassCard(cornerRadius: 22)
        .frame(maxWidth: Metrics.readingWidth)
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity)
    }

    private var nowPlaying: some View {
        Button {
            reader.open(surah: surah.id, ayah: player.currentAyah ?? 1)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(surah.nameTransliterated)
                    .font(.callout.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                if player.isLocalFile {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .help("Playing the downloaded file")
                }
            }
            .lineLimit(1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Show the recited ayah")
    }

    private var detail: String {
        var parts = [player.reciter.name]
        if let ayah = player.currentAyah {
            parts.insert("Ayah \(ayah) of \(surah.ayahCount)", at: 0)
        }
        return parts.joined(separator: " · ")
    }

    private func errorRow(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Button("Try Again") { player.play(surah: surah, reciter: player.reciter) }
                .buttonStyle(.link)
        }
        .font(.caption)
    }
}

private struct PlayerTransport: View {
    let isLastSurah: Bool

    @Environment(AudioPlayerService.self) private var player

    var body: some View {
        HStack(spacing: 6) {
            Button("Previous", systemImage: "backward.fill", action: player.previous)
                .buttonStyle(.icon(size: 30))
                .help("Restart, or previous surah")
            Button {
                player.togglePlayPause()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .frame(width: 24, height: 24)
                    .contentTransition(.symbolEffect(.replace))
            }
            .glassButtonStyle(prominent: true)
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
            Button("Next Surah", systemImage: "forward.fill", action: player.next)
                .buttonStyle(.icon(size: 30))
                .disabled(isLastSurah)
                .help("Next surah")
        }
    }
}

private struct PlayerScrubber: View {
    @Environment(AudioPlayerService.self) private var player

    var body: some View {
        HStack(spacing: 8) {
            Text(Self.format(player.currentTime))
                .frame(minWidth: 34, alignment: .trailing)
            Slider(
                value: Binding(get: { player.currentTime }, set: { player.seek(to: $0) }),
                in: 0...max(player.duration, 1)
            )
            .controlSize(.mini)
            .disabled(player.duration == 0)
            .accessibilityLabel("Playback position")
            .accessibilityValue("\(Self.format(player.currentTime)) of \(Self.format(player.duration))")
            Text(Self.format(player.duration))
                .frame(minWidth: 34, alignment: .leading)
            if player.isBuffering {
                ProgressView().controlSize(.mini)
            }
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
    }

    static func format(_ seconds: Double) -> String {
        let total = Int(seconds)
        return total >= 3600
            ? String(format: "%d:%02d:%02d", total / 3600, total / 60 % 60, total % 60)
            : String(format: "%d:%02d", total / 60, total % 60)
    }
}
