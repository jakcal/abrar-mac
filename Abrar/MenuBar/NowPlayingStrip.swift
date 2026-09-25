import SwiftUI

/// Compact recitation controls in the menu bar panel.
struct NowPlayingStrip: View {
    let surah: Surah
    var openReader: () -> Void

    @Environment(AudioPlayerService.self) private var player

    var body: some View {
        HStack(spacing: 10) {
            Button(action: openReader) {
                HStack(spacing: 10) {
                    Image(systemName: "waveform")
                        .symbolEffect(.variableColor.iterative, isActive: player.isPlaying)
                        .foregroundStyle(.tint)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(surah.nameTransliterated)
                            .font(.callout.weight(.medium))
                            .lineLimit(1)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Show in Quran window")

            Button(player.isPlaying ? "Pause" : "Play", systemImage: player.isPlaying ? "pause.fill" : "play.fill") {
                player.togglePlayPause()
            }
            .buttonStyle(.icon)
            Button("Next Surah", systemImage: "forward.fill", action: player.next)
                .buttonStyle(.icon)
                .disabled(surah.id >= 114)
        }
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .padding(.vertical, 8)
        .glassCard(cornerRadius: 14)
    }

    private var subtitle: String {
        if let ayah = player.currentAyah {
            return "Ayah \(ayah) · \(player.reciter.name)"
        }
        return player.reciter.name
    }
}
