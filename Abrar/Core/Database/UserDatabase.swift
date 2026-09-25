import Foundation
import GRDB

/// Read/write store for user data: settings, bookmarks and reading position.
struct UserDatabase: Sendable {
    let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) throws {
        self.dbQueue = dbQueue
        try Self.migrator.migrate(dbQueue)
    }

    static func open(at url: URL) throws -> UserDatabase {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        var config = Configuration()
        config.label = "user"
        return try UserDatabase(dbQueue: DatabaseQueue(path: url.path, configuration: config))
    }

    static func inMemory() throws -> UserDatabase {
        try UserDatabase(dbQueue: DatabaseQueue())
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: "settings") { t in
                t.primaryKey("id", .integer).check { $0 == 1 }
                t.column("json", .text).notNull()
            }
            try db.create(table: "bookmarks") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("surah", .integer).notNull()
                t.column("ayah", .integer).notNull()
                t.column("createdAt", .datetime).notNull()
                t.uniqueKey(["surah", "ayah"])
            }
            try db.create(table: "readingPosition") { t in
                t.primaryKey("id", .integer).check { $0 == 1 }
                t.column("surah", .integer).notNull()
                t.column("ayah", .integer).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
        }
        migrator.registerMigration("v2-ayah-timings") { db in
            try db.create(table: "ayahTimings") { t in
                t.column("reciterID", .text).notNull()
                t.column("surah", .integer).notNull()
                t.column("json", .text).notNull()
                t.primaryKey(["reciterID", "surah"])
            }
        }
        migrator.registerMigration("v3-listening-positions") { db in
            try db.create(table: "listeningPositions") { t in
                t.column("reciterID", .text).notNull()
                t.column("surah", .integer).notNull()
                t.column("position", .double).notNull()
                t.column("duration", .double).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.primaryKey(["reciterID", "surah"])
            }
        }
        return migrator
    }
}
