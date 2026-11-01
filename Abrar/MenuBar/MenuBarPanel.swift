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
                    NextPrayerCard(
                        next: next,
                        window: schedule.nextPrayerWindow,
                        timeZone: place.timeZone,
                        now: schedule.now,
                        isSoon: store.settings.highlightSoon
                            && PrayerFormatting.isSoon(next.date, now: schedule.now, within: store.settings.highlightSoonMinutes)
                    )
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
        return VStack(spacing: 2) {
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
        .padding(4)
        .contentCard(cornerRadius: 14)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                BrandMark()
                Spacer()
                if place != nil {
                    Button("Change Location", systemImage: "location", action: editLocation)
                        .buttonStyle(.icon)
                        .foregroundStyle(.secondary)
                        .help(place?.displayName ?? "Change location")
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(place?.name ?? "Prayer Times")
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 5) {
                    Text(gregorianText)
                    Text("·").foregroundStyle(.tertiary)
                    Text(hijriText)
                        .foregroundStyle(Color.gold)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, 4)
    }

    private var timeZone: TimeZone { place?.timeZone ?? .current }

    private var gregorianText: String {
        var style = Date.FormatStyle.dateTime.weekday(.wide).day().month(.wide)
        style.timeZone = timeZone
        return now.formatted(style)
    }

    /// Umm al-Qura date, e.g. "10 Jumada I 1448 AH".
    private var hijriText: String {
        var style = Date.FormatStyle.dateTime.day().month(.wide).year().era()
        style.calendar = Calendar(identifier: .islamicUmmAlQura)
        style.timeZone = timeZone
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
