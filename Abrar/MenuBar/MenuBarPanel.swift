import SwiftUI

struct MenuBarPanel: View {
    @Environment(PrayerSchedule.self) private var schedule
    @Environment(SettingsStore.self) private var store
    @Environment(AudioPlayerService.self) private var player
    @Environment(ReaderModel.self) private var reader
    @Environment(UpdateController.self) private var updates
    @Environment(AdhkarModel.self) private var adhkar
    @Environment(AppModel.self) private var app
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PanelHeader(place: schedule.place, now: schedule.now, editLocation: showSettings)
            if let today = schedule.today, let place = schedule.place {
                if let next = schedule.nextPrayer {
                    NextPrayerCard(next: next, window: schedule.nextPrayerWindow, timeZone: place.timeZone, now: schedule.now)
                }
                prayerList(today, timeZone: place.timeZone)
            } else {
                LocationPrompt(chooseCity: showSettings)
            }
            if let session = adhkarDue {
                AdhkarStrip(session: session) { app.showAdhkar(session) }
            }
            if let surah = player.surah {
                NowPlayingStrip(surah: surah) { showReader(at: surah) }
            }
            if let release = updates.available {
                UpdateBanner(release: release, download: updates.download)
            }
            PanelFooter(
                continueSurah: reader.selectedSurah,
                openQuran: { showReader() },
                openAdhkar: { app.showAdhkar(currentAdhkar ?? .morning) },
                openSettings: showSettings
            )
        }
        .padding(12)
        .frame(width: Metrics.panelWidth)
    }

    private func prayerList(_ day: PrayerDay, timeZone: TimeZone) -> some View {
        let current = schedule.currentPrayer?.prayer
        return VStack(spacing: 1) {
            ForEach(day.times) { time in
                PrayerRowView(
                    time: time,
                    timeZone: timeZone,
                    isCurrent: time.prayer.isObligatory && time.prayer == current,
                    isNext: time.id == schedule.nextPrayer?.id,
                    isMuted: time.prayer.isObligatory && !store.settings.notifiedPrayers.contains(time.prayer),
                    now: schedule.now
                )
            }
        }
    }

    private var currentAdhkar: AdhkarSession? {
        AdhkarSession.current(in: schedule.today?.times ?? [], at: schedule.now)
    }

    /// The adhkar for now, if the user turned them on and hasn't finished them.
    private var adhkarDue: AdhkarSession? {
        guard let session = currentAdhkar, store.settings.adhkar.isEnabled(session) else { return nil }
        let items = AdhkarCatalog.items(for: session)
        return adhkar.completedCount(in: session) < items.count ? session : nil
    }

    private func showReader(at surah: Surah? = nil) {
        if let surah {
            reader.open(surah: surah.id, ayah: player.currentAyah ?? 1)
        }
        openWindow(id: WindowID.quran)
        NSApp.activate()
    }

    private func showSettings() {
        NSApp.activate()
        openSettings()
    }
}

private struct PanelHeader: View {
    let place: Place?
    let now: Date
    var editLocation: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BrandMark()
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(place?.name ?? "Prayer Times")
                        .font(.title3.weight(.semibold))
                        .lineLimit(1)
                    Text(dateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if place != nil {
                    Button("Change Location", systemImage: "location", action: editLocation)
                        .buttonStyle(.icon)
                        .foregroundStyle(.secondary)
                        .help(place?.displayName ?? "Change location")
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private var dateText: String {
        var style = Date.FormatStyle(date: .complete, time: .omitted)
        style.timeZone = place?.timeZone ?? .current
        return now.formatted(style)
    }
}

private struct PanelFooter: View {
    let continueSurah: Surah?
    var openQuran: () -> Void
    var openAdhkar: () -> Void
    var openSettings: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Button(action: openQuran) {
                Label(continueSurah.map { "Continue \($0.nameTransliterated)" } ?? "Open Quran", systemImage: "book.pages")
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
            .glassButtonStyle()
            .help(continueSurah == nil ? "Open the Quran" : "Open the Quran where you left off")
            .controlSize(.large)
            Button("Adhkar", systemImage: "sparkles", action: openAdhkar)
                .buttonStyle(.icon(size: 32))
                .foregroundStyle(.secondary)
                .help("Open the daily adhkar")
            Button("Settings", systemImage: "gearshape", action: openSettings)
                .buttonStyle(.icon(size: 32))
                .foregroundStyle(.secondary)
                .help("Settings")
            Button("Quit Abrar", systemImage: "power") { NSApp.terminate(nil) }
                .buttonStyle(.icon(size: 32))
                .foregroundStyle(.secondary)
                .keyboardShortcut("q")
                .help("Quit Abrar")
        }
    }
}
