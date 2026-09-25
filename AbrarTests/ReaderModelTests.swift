import Foundation
import Testing
@testable import Abrar

@MainActor
struct ReaderModelTests {
    @Test func selectingSurahLoadsItsAyahs() throws {
        let reader = ReaderModel(
            quran: try GRDBQuranStore.bundled(),
            library: GRDBLibraryRepository(database: try UserDatabase.inMemory())
        )
        reader.load()
        reader.selectedSurahID = 1
        #expect(reader.ayahs.count == 7)
        reader.selectedSurahID = 112
        #expect(reader.ayahs.count == 4)
        #expect(reader.ayahs.allSatisfy { $0.surah == 112 })
    }
}
