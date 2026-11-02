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

    @Test func goToOpensValidAyahsOnly() throws {
        let reader = ReaderModel(
            quran: try GRDBQuranStore.bundled(),
            library: GRDBLibraryRepository(database: try UserDatabase.inMemory())
        )
        reader.load()
        #expect(reader.go(to: "2:255"))
        #expect(reader.selectedSurahID == 2)
        #expect(reader.scrollTarget == 255)
        #expect(reader.translations.count == 286)
        #expect(reader.go(to: "10"))
        #expect(reader.selectedSurahID == 2)
        #expect(reader.scrollTarget == 10)
        #expect(!reader.go(to: "2:287"))
        #expect(!reader.go(to: "hello"))
        #expect(reader.startsJuz(reader.ayahs[141]) == 2)
        #expect(reader.startsJuz(reader.ayahs[0]) == nil)
    }
}
