import Foundation
import Testing
@testable import Abrar

struct QuranStoreTests {
    private let store: GRDBQuranStore

    init() throws {
        store = try GRDBQuranStore.bundled()
    }

    @Test func has114Surahs() throws {
        let surahs = try store.surahs()
        #expect(surahs.count == 114)
        #expect(surahs.map(\.id) == Array(1...114))
        #expect(surahs.reduce(0) { $0 + $1.ayahCount } == 6236)
    }

    @Test func fatiha() throws {
        let surah = try #require(try store.surah(id: 1))
        #expect(surah.nameArabic == "الفاتحة")
        #expect(surah.nameTransliterated == "Al-Faatiha")
        #expect(surah.bismillah == nil)

        let ayahs = try store.ayahs(inSurah: 1)
        #expect(ayahs.count == 7)
        #expect(ayahs.first?.text == "بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ")
        #expect(ayahs.map(\.number) == Array(1...7))
    }

    @Test func bismillahOnlyWhereExpected() throws {
        #expect(try store.surah(id: 9)?.bismillah == nil)
        #expect(try store.surah(id: 2)?.bismillah != nil)
    }

    @Test func ayahCountsMatchSurahMetadata() throws {
        for id in [2, 18, 36, 114] {
            let surah = try #require(try store.surah(id: id))
            #expect(try store.ayahs(inSurah: id).count == surah.ayahCount)
        }
    }

    @Test(arguments: [
        ("fatiha", 1), ("Al Baqara", 2), ("the cow", 2), ("36", 36), ("الكهف", 18), ("yaseen", 36),
    ])
    func search(query: String, expected: Int) throws {
        #expect(try store.searchSurahs(query).map(\.id).contains(expected))
    }

    @Test func emptySearchReturnsAll() throws {
        #expect(try store.searchSurahs("  ").count == 114)
        #expect(try store.searchSurahs("zzzz").isEmpty)
    }

    @Test func attributionIsKept() throws {
        let notice = try store.textAttribution()
        #expect(notice.contains("Tanzil Quran Text"))
        #expect(notice.contains("CHANGING IT IS NOT ALLOWED"))
    }

    @Test func translationCoversEveryAyah() throws {
        let fatiha = try store.translations(inSurah: 1)
        #expect(fatiha.count == 7)
        #expect(fatiha[1]?.hasPrefix("In the name of Allah") == true)
        #expect(try store.translations(inSurah: 2).count == 286)
    }

    @Test func juzAndPageMarks() throws {
        let juzs = try store.juzStarts()
        let pages = try store.pageStarts()
        #expect(juzs.count == 30)
        #expect(pages.count == 604)
        #expect(juzs.index(surah: 1, ayah: 1) == 1)
        #expect(juzs.index(surah: 2, ayah: 141) == 1)
        #expect(juzs.index(surah: 2, ayah: 142) == 2)
        #expect(juzs.index(surah: 114, ayah: 6) == 30)
        #expect(pages.index(surah: 1, ayah: 1) == 1)
        #expect(pages.index(surah: 114, ayah: 6) == 604)
    }

    @Test func searchAcceptsAyahReference() throws {
        #expect(try store.searchSurahs("2:255").map(\.id) == [2])
    }

    @Test(arguments: [("2:255", 2, 255), ("18 10", 18, 10), ("36.1", 36, 1)])
    func parsesReference(text: String, surah: Int, ayah: Int) {
        #expect(AyahReference(text) == AyahReference(surah: surah, ayah: ayah))
    }

    @Test(arguments: ["", "2", "0:1", "115:1", "2:0", "a:b", "1:2:3"])
    func rejectsBadReference(text: String) {
        #expect(AyahReference(text) == nil)
    }
}
