import Foundation

enum PrayerName: String, Codable, CaseIterable, Identifiable, Sendable {
    case fajr, sunrise, dhuhr, asr, maghrib, isha

    static let obligatory: [PrayerName] = [.fajr, .dhuhr, .asr, .maghrib, .isha]

    var id: String { rawValue }

    var isObligatory: Bool { self != .sunrise }

    var displayName: String {
        switch self {
        case .fajr: "Fajr"
        case .sunrise: "Sunrise"
        case .dhuhr: "Dhuhr"
        case .asr: "Asr"
        case .maghrib: "Maghrib"
        case .isha: "Isha"
        }
    }

    var arabicName: String {
        switch self {
        case .fajr: "الفجر"
        case .sunrise: "الشروق"
        case .dhuhr: "الظهر"
        case .asr: "العصر"
        case .maghrib: "المغرب"
        case .isha: "العشاء"
        }
    }
}
