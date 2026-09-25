import SwiftUI

struct MenuBarPanel: View {
    @Environment(PrayerSchedule.self) private var schedule
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if let today = schedule.today, let place = schedule.place {
                VStack(spacing: 2) {
                    ForEach(today.times) { time in
                        PrayerRowView(
                            time: time,
                            timeZone: place.timeZone,
                            isCurrent: time.prayer == schedule.currentPrayer?.prayer,
                            isNext: time.id == schedule.nextPrayer?.id,
                            now: schedule.now
                        )
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Set your location to see prayer times.")
                        .foregroundStyle(.secondary)
                    Button("Choose Location…", action: showSettings)
                }
            }
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 280)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(schedule.place?.displayName ?? "Abrar")
                .font(.headline)
            Text(schedule.now.formatted(date: .complete, time: .omitted))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        HStack {
            Button("Quran", systemImage: "book") {
                openWindow(id: WindowID.quran)
                NSApp.activate()
            }
            Button("Settings", systemImage: "gearshape", action: showSettings)
            Spacer()
            Button("Quit", systemImage: "power") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .labelStyle(.titleAndIcon)
        .buttonStyle(.borderless)
    }

    private func showSettings() {
        NSApp.activate()
        openSettings()
    }
}
