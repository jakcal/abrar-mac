import SwiftUI

struct SpeedMenu: View {
    @Environment(SettingsStore.self) private var store

    var body: some View {
        Menu {
            Picker("Playback Speed", selection: Bindable(store).settings.playbackRate) {
                ForEach(AudioPlayerService.playbackRates, id: \.self) { rate in
                    Text(Self.label(rate)).tag(rate)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Text(Self.label(store.settings.playbackRate))
                .monospacedDigit()
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Playback speed")
    }

    static func label(_ rate: Double) -> String {
        rate.formatted(.number.precision(.fractionLength(0...2))) + "×"
    }
}

struct SleepTimerMenu: View {
    @Environment(AudioPlayerService.self) private var player

    var body: some View {
        Menu {
            ForEach(SleepTimer.presetMinutes, id: \.self) { minutes in
                Button("\(minutes) minutes") { player.setSleepTimer(minutes: minutes) }
            }
            Button("End of Surah") { player.setSleepTimerToEndOfSurah() }
            if player.sleepTimer != nil {
                Divider()
                Button("Turn Off Sleep Timer") { player.cancelSleepTimer() }
            }
        } label: {
            label
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Sleep timer")
    }

    @ViewBuilder
    private var label: some View {
        switch player.sleepTimer {
        case nil:
            Image(systemName: "moon.zzz")
        case .endOfSurah:
            Label("End of surah", systemImage: "moon.zzz.fill")
        case let .at(deadline):
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Label(Self.remaining(until: deadline, now: context.date), systemImage: "moon.zzz.fill")
                    .monospacedDigit()
            }
        }
    }

    private static func remaining(until deadline: Date, now: Date) -> String {
        let seconds = max(0, Int(deadline.timeIntervalSince(now).rounded(.up)))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
