import Foundation
import GRDB

protocol LibraryRepository: Sendable {
    func bookmarks() throws -> [Bookmark]
    func addBookmark(surah: Int, ayah: Int) throws
    func removeBookmark(surah: Int, ayah: Int) throws
    func readingPosition() throws -> ReadingPosition?
    func saveReadingPosition(_ position: ReadingPosition) throws
}

struct GRDBLibraryRepository: LibraryRepository {
    let database: UserDatabase

    func bookmarks() throws -> [Bookmark] {
        try database.dbQueue.read { db in
            try Bookmark.order(Column("surah"), Column("ayah")).fetchAll(db)
        }
    }

    func addBookmark(surah: Int, ayah: Int) throws {
        try database.dbQueue.write { db in
            var bookmark = Bookmark(id: nil, surah: surah, ayah: ayah, createdAt: Date())
            try bookmark.insert(db, onConflict: .ignore)
        }
    }

    func removeBookmark(surah: Int, ayah: Int) throws {
        _ = try database.dbQueue.write { db in
            try Bookmark
                .filter(Column("surah") == surah && Column("ayah") == ayah)
                .deleteAll(db)
        }
    }

    func readingPosition() throws -> ReadingPosition? {
        try database.dbQueue.read { db in
            try Row.fetchOne(db, sql: "SELECT surah, ayah FROM readingPosition WHERE id = 1")
                .map { ReadingPosition(surah: $0["surah"], ayah: $0["ayah"]) }
        }
    }

    func saveReadingPosition(_ position: ReadingPosition) throws {
        try database.dbQueue.write { db in
            try db.execute(
                sql: """
                    INSERT INTO readingPosition (id, surah, ayah, updatedAt) VALUES (1, ?, ?, ?)
                    ON CONFLICT(id) DO UPDATE SET
                        surah = excluded.surah, ayah = excluded.ayah, updatedAt = excluded.updatedAt
                    """,
                arguments: [position.surah, position.ayah, Date()]
            )
        }
    }
}
