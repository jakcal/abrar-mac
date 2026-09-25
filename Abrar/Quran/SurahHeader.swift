import SwiftUI

struct SurahHeader: View {
    let surah: Surah

    @Environment(SettingsStore.self) private var store
    @Environment(AudioPlayerService.self) private var player

    private var reciter: Reciter { Reciter.with(id: store.settings.reciterID) }

    private var isCurrent: Bool { player.surah?.id == surah.id }

    private var resumeTime: Double? { player.resumeTime(for: surah, reciter: reciter) }

    private var playTitle: String {
        if isCurrent { return player.isPlaying ? "Pause" : "Play" }
        guard let resumeTime else { return "Play" }
        return "Resume \(Duration.seconds(resumeTime).formatted(.time(pattern: .minuteSecond)))"
    }

    var body: some View {
        VStack(spacing: 14) {
            Text("سُورَةُ \(surah.nameArabic)")
                .font(QuranFont.font(size: store.settings.quranFontSize + 6))
            HStack(spacing: 12) {
                Button {
                    isCurrent ? player.togglePlayPause() : player.play(surah: surah, reciter: reciter)
                } label: {
                    Label(playTitle, systemImage: isCurrent && player.isPlaying ? "pause.fill" : "play.fill")
                        .monospacedDigit()
                }
                .buttonStyle(.borderedProminent)

                if !isCurrent, resumeTime != nil {
                    Button("Play from Start", systemImage: "arrow.counterclockwise") {
                        player.play(surah: surah, reciter: reciter, fromAyah: 1)
                    }
                }

                DownloadControl(surah: surah, reciter: reciter)
            }
            Text(reciter.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let bismillah = surah.bismillah {
                Text(bismillah)
                    .font(QuranFont.font(size: store.settings.quranFontSize))
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }
}
