import AppKit
import Observation
import UserNotifications

/// Owns the long-lived models and wires them together.
@MainActor
@Observable
final class AppModel {
    let services: AppServices
    let settings: SettingsStore
    let schedule: PrayerSchedule
    let reader: ReaderModel
    let player: AudioPlayerService
    let downloads: DownloadManager
    let location: LocationController
    let updates: UpdateController
    let adhkar: AdhkarModel

    @ObservationIgnored private let adhan: AdhanPlaying = AdhanAudioPlayer()
    @ObservationIgnored private var notificationPresenter: NotificationPresenter?
    @ObservationIgnored private var adhkarWindow: AdhkarWindowController?
    @ObservationIgnored private var systemEvents: SystemEvents?
    @ObservationIgnored private var rescheduleTask: Task<Void, Never>?

    init(services: AppServices = .live()) {
        self.services = services
        settings = SettingsStore(repository: services.settings)
        schedule = PrayerSchedule(calculator: services.calculator)
        reader = ReaderModel(quran: services.quran, library: services.library)
        player = AudioPlayerService(
            storage: services.audioStorage,
            quran: services.quran,
            timings: services.timings,
            positions: services.listeningPositions,
            reciter: Reciter.with(id: settings.settings.reciterID)
        )
        player.setRate(settings.settings.playbackRate)
        downloads = DownloadManager(storage: services.audioStorage, timings: services.timings)
        location = LocationController(provider: CoreLocationService(), store: settings)
        updates = UpdateController(checker: services.releases)
        adhkar = AdhkarModel(quran: services.quran)

        settings.onChange = { [weak self] old, new in self?.settingsChanged(from: old, to: new) }
        schedule.onPrayerTime = { [weak self] time in self?.prayerStarted(time) }
        QuranFont.register()
        reader.load()
        schedule.update(place: settings.settings.activePlace, config: settings.settings.calculationConfig)

        if !AppPaths.isRunningTests {
            start()
        }
    }

    func playAdhan() {
        adhan.play()
    }

    func stopAdhan() {
        adhan.stop()
    }

    func showAdhkar(_ session: AdhkarSession) {
        let controller = adhkarWindow ?? AdhkarWindowController(model: adhkar)
        adhkarWindow = controller
        controller.show(session)
    }

    func fireTestNotification() {
        Task {
            _ = await services.notifications.requestAuthorization()
            await services.notifications.scheduleTestNotification(after: 5)
        }
    }

    private func start() {
        let presenter = NotificationPresenter { [weak self] session in self?.showAdhkar(session) }
        notificationPresenter = presenter
        UNUserNotificationCenter.current().delegate = presenter
        schedule.start()
        player.start()
        try? FileManager.default.removeItem(at: AppPaths.legacyAudio)
        downloads.start(sessionIdentifier: "app.abrar.Abrar.downloads")
        systemEvents = SystemEvents { [weak self] in self?.systemChanged() }
        Task {
            _ = await services.notifications.requestAuthorization()
            scheduleNotifications()
        }
        if settings.settings.checkForUpdates {
            updates.startAutomaticChecks()
        }
        if settings.settings.locationMode == .automatic {
            Task { await location.refresh() }
        }
    }

    private func settingsChanged(from old: AppSettings, to new: AppSettings) {
        let placeChanged = old.activePlace != new.activePlace
        let configChanged = old.calculationConfig != new.calculationConfig
        if placeChanged || configChanged {
            schedule.update(place: new.activePlace, config: new.calculationConfig)
        }
        if placeChanged || configChanged || old.notifiedPrayers != new.notifiedPrayers
            || old.prayerSounds != new.prayerSounds || old.dhikrReminders != new.dhikrReminders
            || old.adhkar != new.adhkar {
            scheduleNotifications()
        }
        if old.playbackRate != new.playbackRate {
            player.setRate(new.playbackRate)
        }
        if old.reciterID != new.reciterID {
            player.setReciter(Reciter.with(id: new.reciterID))
        }
        if old.checkForUpdates != new.checkForUpdates {
            new.checkForUpdates ? updates.startAutomaticChecks() : updates.stopAutomaticChecks()
        }
        if old.locationMode != new.locationMode, new.locationMode == .automatic {
            Task { await location.refresh() }
        }
    }

    private func systemChanged() {
        schedule.recalculate()
        scheduleNotifications()
    }

    private func prayerStarted(_ time: PrayerTime) {
        let current = settings.settings
        guard current.playFullAdhan,
              current.notifiedPrayers.contains(time.prayer),
              current.prayerSounds[time.prayer] == .adhan else { return }
        player.pause()
        adhan.play()
    }

    /// Debounced so rapid setting changes (steppers) don't race each other.
    private func scheduleNotifications() {
        rescheduleTask?.cancel()
        rescheduleTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard let self, !Task.isCancelled else { return }
            let current = settings.settings
            let days = schedule.upcomingDays(7)
            if let place = schedule.place {
                await services.notifications.reschedule(
                    days: days,
                    place: place,
                    enabled: current.notifiedPrayers,
                    sounds: current.prayerSounds
                )
            }
            await services.notifications.reschedule(dhikr: DhikrPlanner.plan(
                reminders: current.dhikrReminders,
                adhkar: current.adhkar,
                days: days,
                now: Date()
            ))
        }
    }
}
