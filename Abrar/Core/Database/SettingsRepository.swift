import Foundation
import GRDB

protocol SettingsRepository: Sendable {
    func load() throws -> AppSettings
    func save(_ settings: AppSettings) throws
}

struct GRDBSettingsRepository: SettingsRepository {
    let database: UserDatabase

    func load() throws -> AppSettings {
        let json = try database.dbQueue.read { db in
            try String.fetchOne(db, sql: "SELECT json FROM settings WHERE id = 1")
        }
        guard let json else { return AppSettings() }
        return try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))
    }

    func save(_ settings: AppSettings) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let json = String(decoding: try encoder.encode(settings), as: UTF8.self)
        try database.dbQueue.write { db in
            try db.execute(
                sql: """
                    INSERT INTO settings (id, json) VALUES (1, ?)
                    ON CONFLICT(id) DO UPDATE SET json = excluded.json
                    """,
                arguments: [json]
            )
        }
    }
}
