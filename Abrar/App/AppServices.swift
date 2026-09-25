import Foundation

/// Concrete service implementations. Swap members for fakes in tests or previews.
struct AppServices: Sendable {
    var quran: QuranStore
    var library: LibraryRepository
    var settings: SettingsRepository
    var calculator: PrayerCalculating
    var notifications: NotificationScheduling
    var cities: CitySearching
    var launchAtLogin: LaunchAtLoginControlling
    var audioStorage: AudioStorage
    var timings: AyahTimingProviding
    var listeningPositions: ListeningPositionStore
    var releases: ReleaseChecking

    static func live() -> AppServices {
        let quran: QuranStore
        do {
            quran = try GRDBQuranStore.bundled()
        } catch {
            fatalError("quran.sqlite is missing from the app bundle: \(error)")
        }
        let userDatabase = openUserDatabase()
        return AppServices(
            quran: quran,
            library: GRDBLibraryRepository(database: userDatabase),
            settings: GRDBSettingsRepository(database: userDatabase),
            calculator: AdhanPrayerCalculator(),
            notifications: UserNotificationScheduler(),
            cities: CityCatalog.bundled(),
            launchAtLogin: SMAppLaunchAtLogin(),
            audioStorage: AudioStorage(root: AppPaths.audio),
            timings: QDCTimingService(cache: GRDBTimingCache(database: userDatabase)),
            listeningPositions: GRDBListeningPositionStore(database: userDatabase),
            releases: GitHubReleaseChecker()
        )
    }

    /// Falls back to an in-memory database so the app stays usable if the file can't be opened.
    private static func openUserDatabase() -> UserDatabase {
        if !AppPaths.isRunningTests, let database = try? UserDatabase.open(at: AppPaths.userDatabase) {
            return database
        }
        do {
            return try UserDatabase.inMemory()
        } catch {
            fatalError("Could not create an in-memory database: \(error)")
        }
    }
}
