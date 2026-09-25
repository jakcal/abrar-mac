import Foundation
import GRDB

protocol QuranStore: Sendable {
    func surahs() throws -> [Surah]
    func surah(id: Int) throws -> Surah?
    func ayahs(inSurah surah: Int) throws -> [Ayah]
    func searchSurahs(_ query: String) throws -> [Surah]
    func textAttribution() throws -> String
}

enum QuranStoreError: Error {
    case missingDatabase
}

struct GRDBQuranStore: QuranStore {
    private let dbQueue: DatabaseQueue

    init(path: String) throws {
        var config = Configuration()
        config.readonly = true
        config.label = "quran"
        dbQueue = try DatabaseQueue(path: path, configuration: config)
    }

    static func bundled(in bundle: Bundle = .main) throws -> GRDBQuranStore {
        guard let url = bundle.url(forResource: "quran", withExtension: "sqlite") else {
            throw QuranStoreError.missingDatabase
        }
        return try GRDBQuranStore(path: url.path)
    }

    func surahs() throws -> [Surah] {
        try dbQueue.read { db in
            try Surah.order(Column("id")).fetchAll(db)
        }
    }

    func surah(id: Int) throws -> Surah? {
        try dbQueue.read { db in
            try Surah.fetchOne(db, key: id)
        }
    }

    func ayahs(inSurah surah: Int) throws -> [Ayah] {
        try dbQueue.read { db in
            try Ayah
                .filter(Column("surah") == surah)
                .order(Column("number"))
                .fetchAll(db)
        }
    }

    func searchSurahs(_ query: String) throws -> [Surah] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return try surahs() }

        if let number = Int(trimmed) {
            return try surah(id: number).map { [$0] } ?? []
        }

        let key = Self.searchKey(trimmed)
        let compactKey = key.replacingOccurrences(of: " ", with: "")
        let arabic = trimmed.applyingTransform(.stripDiacritics, reverse: false) ?? trimmed
        return try dbQueue.read { db in
            try Surah.fetchAll(
                db,
                sql: """
                    SELECT * FROM surahs
                    WHERE (? <> '' AND search_key LIKE ?)
                       OR (? <> '' AND search_key LIKE ?)
                       OR name_arabic LIKE ?
                    ORDER BY id
                    """,
                arguments: [key, "%\(key)%", compactKey, "%\(compactKey)%", "%\(arabic)%"]
            )
        }
    }

    func textAttribution() throws -> String {
        try dbQueue.read { db in
            try String.fetchOne(db, sql: "SELECT value FROM meta WHERE key = 'tanzil_copyright'") ?? ""
        }
    }

    /// Mirrors `search_key()` in scripts/build_quran_db.py.
    static func searchKey(_ text: String) -> String {
        let lowered = text.lowercased().filter { ("a"..."z").contains($0) || ("0"..."9").contains($0) || $0 == " " }
        var result = ""
        for character in lowered {
            if "aeiou".contains(character), result.last == character { continue }
            result.append(character)
        }
        return result
    }
}
