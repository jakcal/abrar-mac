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

struct ReadingPosition: Codable, Equatable, Sendable {
    var surah: Int
    var ayah: Int
}
