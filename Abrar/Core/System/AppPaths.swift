import Foundation

enum AppPaths {
    static var applicationSupport: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Abrar", isDirectory: true)
    }

    static var userDatabase: URL {
        applicationSupport.appendingPathComponent("user.sqlite")
    }

    static var audio: URL {
        applicationSupport.appendingPathComponent("Recitations", isDirectory: true)
    }

    /// mp3quran.net downloads from pre-0.1 builds; their timing doesn't match quran.com's.
    static var legacyAudio: URL {
        applicationSupport.appendingPathComponent("Audio", isDirectory: true)
    }

    /// Recordings the user added.
    static var customAdhans: URL {
        applicationSupport.appendingPathComponent("Adhans", isDirectory: true)
    }

    /// Besides the app bundle, where UserNotifications looks for custom sounds.
    static var notificationSounds: URL {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return library.appendingPathComponent("Sounds", isDirectory: true)
    }

    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
