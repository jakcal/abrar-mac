import Foundation
import GRDB

protocol TimingCache: Sendable {
    func timings(reciterID: String, surah: Int) throws -> SurahTimings?
    func store(_ timings: SurahTimings, reciterID: String, surah: Int) throws
}

struct GRDBTimingCache: TimingCache {
    let database: UserDatabase

    func timings(reciterID: String, surah: Int) throws -> SurahTimings? {
        let json = try database.dbQueue.read { db in
            try String.fetchOne(
                db,
                sql: "SELECT json FROM ayahTimings WHERE reciterID = ? AND surah = ?",
                arguments: [reciterID, surah]
            )
        }
        return try json.map { try JSONDecoder().decode(SurahTimings.self, from: Data($0.utf8)) }
    }

    func store(_ timings: SurahTimings, reciterID: String, surah: Int) throws {
        let json = String(decoding: try JSONEncoder().encode(timings), as: UTF8.self)
        try database.dbQueue.write { db in
            try db.execute(
                sql: "INSERT OR REPLACE INTO ayahTimings (reciterID, surah, json) VALUES (?, ?, ?)",
                arguments: [reciterID, surah, json]
            )
        }
    }
}
