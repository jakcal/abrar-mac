import Foundation

/// A phrase the user wrote themselves.
struct CustomDhikr: Codable, Hashable, Identifiable, Sendable {
    var id = UUID()
    var text: String
    var isEnabled = true
}

/// Short reminders spread across the day, rotating through the enabled phrases.
struct DhikrReminders: Codable, Equatable, Sendable {
    static let intervals = [30, 60, 90, 120, 180, 240]

    var isEnabled = false
    /// Minutes between reminders.
    var interval = 60
    /// Minutes from midnight. An end before the start runs past midnight.
    var start = 9 * 60
    var end = 21 * 60
    var sound = AlertSound.tone
    var enabledPhrases: Set<String> = DhikrPhrase.defaultIDs
    var customPhrases: [CustomDhikr] = []

    init() {}

    private enum CodingKeys: String, CodingKey {
        case isEnabled, interval, start, end, sound, enabledPhrases, customPhrases
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = DhikrReminders()
        isEnabled = try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? d.isEnabled
        interval = try c.decodeIfPresent(Int.self, forKey: .interval) ?? d.interval
        start = try c.decodeIfPresent(Int.self, forKey: .start) ?? d.start
        end = try c.decodeIfPresent(Int.self, forKey: .end) ?? d.end
        sound = try c.decodeIfPresent(AlertSound.self, forKey: .sound) ?? d.sound
        enabledPhrases = try c.decodeIfPresent(Set<String>.self, forKey: .enabledPhrases) ?? d.enabledPhrases
        customPhrases = try c.decodeIfPresent([CustomDhikr].self, forKey: .customPhrases) ?? d.customPhrases
    }

    /// Enabled phrases in rotation order: built-in first, then the user's own.
    var rotation: [DhikrPhrase] {
        DhikrPhrase.builtIn.filter { enabledPhrases.contains($0.id) }
            + customPhrases.filter(\.isEnabled).map(DhikrPhrase.init(custom:))
    }
}

enum AdhkarSession: String, Codable, CaseIterable, Identifiable, Sendable {
    case morning, evening, night

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .morning: "Morning"
        case .evening: "Evening"
        case .night: "Before Sleep"
        }
    }

    var title: String {
        switch self {
        case .morning: "Morning Adhkar"
        case .evening: "Evening Adhkar"
        case .night: "Adhkar Before Sleep"
        }
    }

    var arabicTitle: String {
        switch self {
        case .morning: "أذكار الصباح"
        case .evening: "أذكار المساء"
        case .night: "أذكار النوم"
        }
    }

    var symbolName: String {
        switch self {
        case .morning: "sun.max"
        case .evening: "sun.haze"
        case .night: "moon.stars"
        }
    }

    /// Morning from Fajr to Dhuhr, evening from Asr to Isha, night from Isha to Fajr.
    static func current(in times: [PrayerTime], at now: Date) -> AdhkarSession? {
        func date(_ prayer: PrayerName) -> Date? { times.first { $0.prayer == prayer }?.date }
        guard let fajr = date(.fajr), let dhuhr = date(.dhuhr), let asr = date(.asr), let isha = date(.isha) else {
            return nil
        }
        if now < fajr || now >= isha { return .night }
        if now < dhuhr { return .morning }
        if now >= asr { return .evening }
        return nil
    }
}

/// When to be reminded of each set of daily adhkar.
struct AdhkarSettings: Codable, Equatable, Sendable {
    static let delays = [0, 15, 30, 45, 60, 90]

    var morning = false
    /// Minutes after Fajr.
    var morningDelay = 30
    var evening = false
    /// Minutes after Asr.
    var eveningDelay = 30
    var night = false
    /// Minutes from midnight.
    var nightTime = 22 * 60 + 30

    init() {}

    func isEnabled(_ session: AdhkarSession) -> Bool {
        switch session {
        case .morning: morning
        case .evening: evening
        case .night: night
        }
    }

    private enum CodingKeys: String, CodingKey {
        case morning, morningDelay, evening, eveningDelay, night, nightTime
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AdhkarSettings()
        morning = try c.decodeIfPresent(Bool.self, forKey: .morning) ?? d.morning
        morningDelay = try c.decodeIfPresent(Int.self, forKey: .morningDelay) ?? d.morningDelay
        evening = try c.decodeIfPresent(Bool.self, forKey: .evening) ?? d.evening
        eveningDelay = try c.decodeIfPresent(Int.self, forKey: .eveningDelay) ?? d.eveningDelay
        night = try c.decodeIfPresent(Bool.self, forKey: .night) ?? d.night
        nightTime = try c.decodeIfPresent(Int.self, forKey: .nightTime) ?? d.nightTime
    }
}
