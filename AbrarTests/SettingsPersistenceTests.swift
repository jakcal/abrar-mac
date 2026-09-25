import Foundation
import Testing
@testable import Abrar

struct SettingsPersistenceTests {
    @Test func defaultsWhenEmpty() throws {
        let repository = GRDBSettingsRepository(database: try UserDatabase.inMemory())
        #expect(try repository.load() == AppSettings())
    }

    @Test func roundTrip() throws {
        let repository = GRDBSettingsRepository(database: try UserDatabase.inMemory())
        var settings = AppSettings()
        settings.locationMode = .manual
        settings.manualPlace = Place(name: "Rabat", country: "Morocco", latitude: 34.02, longitude: -6.84, timeZoneID: "Africa/Casablanca")
        settings.method = .morocco
        settings.madhab = .hanafi
        settings.fajrAngleOverride = 19.5
        settings.offsets[.isha] = -4
        settings.notifiedPrayers = [.fajr, .maghrib]
        settings.playFullAdhan = true
        settings.reciterID = "husary"
        settings.quranFontSize = 40

        try repository.save(settings)
        try repository.save(settings)
        #expect(try repository.load() == settings)
    }

    @Test func missingKeysFallBackToDefaults() throws {
        let json = #"{"method":"egyptian"}"#
        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))
        var expected = AppSettings()
        expected.method = .egyptian
        #expect(settings == expected)
    }

    @Test @MainActor func storeWritesThroughAndNotifies() throws {
        let repository = GRDBSettingsRepository(database: try UserDatabase.inMemory())
        let store = SettingsStore(repository: repository)
        var changes = 0
        store.onChange = { _, _ in changes += 1 }

        store.settings.reciterID = "minshawi"
        store.settings.reciterID = "minshawi"

        #expect(changes == 1)
        #expect(try repository.load().reciterID == "minshawi")
    }

    @Test func bookmarksAndReadingPosition() throws {
        let library = GRDBLibraryRepository(database: try UserDatabase.inMemory())
        try library.addBookmark(surah: 2, ayah: 255)
        try library.addBookmark(surah: 2, ayah: 255)
        try library.addBookmark(surah: 1, ayah: 1)
        #expect(try library.bookmarks().map { [$0.surah, $0.ayah] } == [[1, 1], [2, 255]])

        try library.removeBookmark(surah: 1, ayah: 1)
        #expect(try library.bookmarks().count == 1)

        #expect(try library.readingPosition() == nil)
        try library.saveReadingPosition(ReadingPosition(surah: 18, ayah: 10))
        try library.saveReadingPosition(ReadingPosition(surah: 36, ayah: 1))
        #expect(try library.readingPosition() == ReadingPosition(surah: 36, ayah: 1))
    }
}

struct ListeningPositionTests {
    @Test func saveLoadAndClear() throws {
        let store = GRDBListeningPositionStore(database: try UserDatabase.inMemory())
        #expect(try store.position(reciterID: "alafasy", surah: 18) == nil)

        try store.save(ListeningPosition(reciterID: "alafasy", surah: 18, position: 120, duration: 1800))
        try store.save(ListeningPosition(reciterID: "alafasy", surah: 18, position: 300, duration: 1800))
        try store.save(ListeningPosition(reciterID: "sudais", surah: 18, position: 60, duration: 1500))
        #expect(try store.position(reciterID: "alafasy", surah: 18)?.position == 300)
        #expect(try store.position(reciterID: "sudais", surah: 18)?.position == 60)

        try store.clear(reciterID: "alafasy", surah: 18)
        #expect(try store.position(reciterID: "alafasy", surah: 18) == nil)
    }

    @Test func resumeSkipsStartAndEnd() {
        #expect(ListeningPosition(reciterID: "a", surah: 1, position: 3, duration: 100).resumeTime == nil)
        #expect(ListeningPosition(reciterID: "a", surah: 1, position: 97, duration: 100).resumeTime == nil)
        #expect(ListeningPosition(reciterID: "a", surah: 1, position: 50, duration: 100).resumeTime == 50)
        #expect(ListeningPosition(reciterID: "a", surah: 1, position: 50, duration: 0).resumeTime == 50)
    }
}
