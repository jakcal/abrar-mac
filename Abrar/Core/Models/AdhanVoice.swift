import Foundation

/// A recording the user added from their own files.
struct CustomAdhan: Codable, Hashable, Identifiable, Sendable {
    var id = UUID()
    var name: String
    /// Kept so the copied file still opens as the right format.
    var fileExtension: String

    var fileName: String { "\(id.uuidString).\(fileExtension)" }
    var soundFileName: String { "Abrar-\(id.uuidString).caf" }
}

/// An adhan recording: a short clip for notifications and the full adhan for playback.
struct AdhanVoice: Hashable, Identifiable, Sendable {
    let id: String
    let name: String
    /// Looked up by UserNotifications in the app bundle, then in Library/Sounds.
    let notificationSound: String
    let fullAdhan: URL?
    let isCustom: Bool

    static let defaultID = "azeez"

    static let builtIn: [AdhanVoice] = [
        bundled(id: defaultID, name: "Aaqib Azeez", file: "adhan"),
        bundled(id: "makkah", name: "Masjid al-Haram, Makkah", file: "adhan_makkah"),
        bundled(id: "fakhri", name: "Sabah Fakhri", file: "adhan_fakhri"),
    ]

    init(custom: CustomAdhan) {
        id = custom.id.uuidString
        name = custom.name
        notificationSound = custom.soundFileName
        fullAdhan = AppPaths.customAdhans.appendingPathComponent(custom.fileName)
        isCustom = true
    }

    private init(id: String, name: String, notificationSound: String, fullAdhan: URL?) {
        self.id = id
        self.name = name
        self.notificationSound = notificationSound
        self.fullAdhan = fullAdhan
        isCustom = false
    }

    private static func bundled(id: String, name: String, file: String) -> AdhanVoice {
        AdhanVoice(
            id: id,
            name: name,
            notificationSound: "\(file).caf",
            fullAdhan: Bundle.main.url(forResource: "\(file)_full", withExtension: "m4a")
        )
    }
}
