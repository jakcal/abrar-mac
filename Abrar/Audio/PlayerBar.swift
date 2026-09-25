import SwiftUI

struct PlayerBar: View {
    @Environment(AudioPlayerService.self) private var player

    var body: some View {
        HStack(spacing: 16) {
            controls
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title).font(.callout.weight(.medium)).lineLimit(1)
                    if player.isLocalFile {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.secondary)
                            .help("Playing downloaded file")
                    }
                    Spacer()
                    Text(player.reciter.displayName).font(.caption).foregroundStyle(.secondary)
                    SpeedMenu()
                    SleepTimerMenu()
                }
                progress
                if let error = player.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    private var title: String {
        guard let surah = player.surah else { return "" }
        return "\(surah.id). \(surah.nameTransliterated)"
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(action: player.previous) {
                Image(systemName: "backward.fill")
            }
            .help("Previous surah")
            Button(action: player.togglePlayPause) {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                    .frame(width: 24)
            }
            Button(action: player.next) {
                Image(systemName: "forward.fill")
            }
            .help("Next surah")
        }
        .buttonStyle(.borderless)
    }

    private var progress: some View {
        HStack(spacing: 8) {
            Text(Self.format(player.currentTime)).monospacedDigit()
            Slider(
                value: Binding(get: { player.currentTime }, set: { player.seek(to: $0) }),
                in: 0...max(player.duration, 1)
            )
            .controlSize(.mini)
            .disabled(player.duration == 0)
            Text(Self.format(player.duration)).monospacedDigit()
            if player.isBuffering {
                ProgressView().controlSize(.mini)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private static func format(_ seconds: Double) -> String {
        let total = Int(seconds)
        return total >= 3600
            ? String(format: "%d:%02d:%02d", total / 3600, total / 60 % 60, total % 60)
            : String(format: "%d:%02d", total / 60, total % 60)
    }
}
