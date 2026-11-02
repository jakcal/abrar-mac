import Foundation
import GRDB

struct Surah: Codable, FetchableRecord, TableRecord, Identifiable, Hashable, Sendable {
    static let databaseTableName = "surahs"

    var id: Int
    var nameArabic: String
    var nameTransliterated: String
    var nameEnglish: String
    var ayahCount: Int
    var revelationType: String
    var bismillah: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case nameArabic = "name_arabic"
        case nameTransliterated = "name_transliterated"
        case nameEnglish = "name_english"
        case ayahCount = "ayah_count"
        case revelationType = "revelation_type"
        case bismillah
    }
}

struct Ayah: Codable, FetchableRecord, TableRecord, Identifiable, Hashable, Sendable {
    static let databaseTableName = "ayahs"

    var surah: Int
    var number: Int
    var text: String

    var id: Int { surah * 1000 + number }
}

struct Bookmark: Codable, FetchableRecord, MutablePersistableRecord, Identifiable, Hashable, Sendable {
    static let databaseTableName = "bookmarks"

    var id: Int64?
    var surah: Int
    var ayah: Int
    var createdAt: Date

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

/// First ayah of a juz or of a mushaf page.
struct QuranMark: Codable, FetchableRecord, Hashable, Sendable {
    var id: Int
    var surah: Int
    var ayah: Int
}

extension [QuranMark] {
    /// The mark that `surah:ayah` falls under. Marks must be sorted by position.
    func index(surah: Int, ayah: Int) -> Int? {
        last { $0.surah < surah || ($0.surah == surah && $0.ayah <= ayah) }?.id
    }
}

/// A "surah:ayah" reference like "2:255".
struct AyahReference: Equatable, Sendable {
    var surah: Int
    var ayah: Int

    /// Accepts "2:255", "2 255" or "2.255". Doesn't check that the ayah exists.
    init?(_ text: String) {
        let parts = text.split(whereSeparator: { ":. ".contains($0) })
        guard parts.count == 2, let surah = Int(parts[0]), let ayah = Int(parts[1]),
              (1...114).contains(surah), ayah >= 1 else { return nil }
        self.surah = surah
        self.ayah = ayah
    }

    init(surah: Int, ayah: Int) {
        self.surah = surah
        self.ayah = ayah
    }
}

struct ReadingPosition: Codable, Equatable, Sendable {
    var surah: Int
    var ayah: Int
}
