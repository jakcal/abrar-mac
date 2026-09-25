import SwiftUI

/// Play / resume, restart, download and reciter choice for a surah.
struct SurahActions: View {
    let surah: Surah

    @Environment(SettingsStore.self) private var store
    @Environment(AudioPlayerService.self) private var player

    private var reciter: Reciter { Reciter.with(id: store.settings.reciterID) }
    private var isCurrent: Bool { player.surah?.id == surah.id }
    private var resumeTime: Double? { player.resumeTime(for: surah, reciter: reciter) }

    var body: some View {
        VStack(spacing: 12) {
            GlassGroup(spacing: 10) {
                HStack(spacing: 10) {
                    playButton
                    if !isCurrent, resumeTime != nil {
                        Button("From Start", systemImage: "arrow.counterclockwise") {
                            player.play(surah: surah, reciter: reciter, fromAyah: 1)
                        }
                        .glassButtonStyle()
                        .help("Play from the first ayah")
                    }
                    DownloadControl(surah: surah, reciter: reciter)
                }
                .controlSize(.large)
            }
            ReciterMenu()
        }
    }

    private var playButton: some View {
        Button {
            isCurrent ? player.togglePlayPause() : player.play(surah: surah, reciter: reciter)
        } label: {
            Label(playTitle, systemImage: isCurrent && player.isPlaying ? "pause.fill" : "play.fill")
                .monospacedDigit()
                .contentTransition(.symbolEffect(.replace))
        }
        .glassButtonStyle(prominent: true)
    }

    private var playTitle: String {
        if isCurrent { return player.isPlaying ? "Pause" : "Resume" }
        guard let resumeTime else { return "Play" }
        return "Resume at \(Duration.seconds(resumeTime).formatted(.time(pattern: .minuteSecond)))"
    }
}

private struct ReciterMenu: View {
    @Environment(SettingsStore.self) private var store

    var body: some View {
        Menu {
            Picker("Reciter", selection: Bindable(store).settings.reciterID) {
                ForEach(Reciter.all) { Text($0.displayName).tag($0.id) }
            }
            .pickerStyle(.inline)
        } label: {
            Label(Reciter.with(id: store.settings.reciterID).displayName, systemImage: "person.wave.2")
                .font(.callout)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .foregroundStyle(.secondary)
        .help("Choose reciter")
    }
}
