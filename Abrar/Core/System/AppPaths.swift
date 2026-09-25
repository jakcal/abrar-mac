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

    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
