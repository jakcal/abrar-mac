import Foundation
import GRDB

struct ListeningPosition: Equatable, Sendable {
    var reciterID: String
    var surah: Int
    var position: Double
    var duration: Double

    /// Where to resume from, or nil when there's nothing worth resuming (start or last 5 s).
    var resumeTime: Double? {
        guard position > 5 else { return nil }
        if duration > 0, duration - position < 5 { return nil }
        return position
    }
}

protocol ListeningPositionStore: Sendable {
    func position(reciterID: String, surah: Int) throws -> ListeningPosition?
    func save(_ position: ListeningPosition) throws
    func clear(reciterID: String, surah: Int) throws
}

struct GRDBListeningPositionStore: ListeningPositionStore {
    let database: UserDatabase

    func position(reciterID: String, surah: Int) throws -> ListeningPosition? {
        try database.dbQueue.read { db in
            try Row.fetchOne(
                db,
                sql: "SELECT position, duration FROM listeningPositions WHERE reciterID = ? AND surah = ?",
                arguments: [reciterID, surah]
            ).map { ListeningPosition(reciterID: reciterID, surah: surah, position: $0["position"], duration: $0["duration"]) }
        }
    }

    func save(_ position: ListeningPosition) throws {
        try database.dbQueue.write { db in
            try db.execute(
                sql: """
                    INSERT OR REPLACE INTO listeningPositions (reciterID, surah, position, duration, updatedAt)
                    VALUES (?, ?, ?, ?, ?)
                    """,
                arguments: [position.reciterID, position.surah, position.position, position.duration, Date()]
            )
        }
    }

    func clear(reciterID: String, surah: Int) throws {
        try database.dbQueue.write { db in
            try db.execute(
                sql: "DELETE FROM listeningPositions WHERE reciterID = ? AND surah = ?",
                arguments: [reciterID, surah]
            )
        }
    }
}
