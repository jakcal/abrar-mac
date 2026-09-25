import Foundation

enum CalculationMethodOption: String, Codable, CaseIterable, Identifiable, Sendable {
    case muslimWorldLeague
    case egyptian
    case karachi
    case ummAlQura
    case dubai
    case moonsightingCommittee
    case northAmerica
    case kuwait
    case qatar
    case singapore
    case tehran
    case turkey
    case morocco
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .muslimWorldLeague: "Muslim World League"
        case .egyptian: "Egyptian General Authority"
        case .karachi: "University of Islamic Sciences, Karachi"
        case .ummAlQura: "Umm al-Qura, Makkah"
        case .dubai: "Dubai"
        case .moonsightingCommittee: "Moonsighting Committee"
        case .northAmerica: "ISNA (North America)"
        case .kuwait: "Kuwait"
        case .qatar: "Qatar"
        case .singapore: "Singapore"
        case .tehran: "Institute of Geophysics, Tehran"
        case .turkey: "Diyanet (Turkey)"
        case .morocco: "Morocco (Habous)"
        case .other: "Custom angles"
        }
    }
}

enum MadhabOption: String, Codable, CaseIterable, Identifiable, Sendable {
    case shafi, hanafi

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .shafi: "Standard (Shafi, Maliki, Hanbali)"
        case .hanafi: "Hanafi"
        }
    }
}

struct PrayerOffsets: Codable, Equatable, Sendable {
    var fajr = 0
    var sunrise = 0
    var dhuhr = 0
    var asr = 0
    var maghrib = 0
    var isha = 0

    subscript(prayer: PrayerName) -> Int {
        get {
            switch prayer {
            case .fajr: fajr
            case .sunrise: sunrise
            case .dhuhr: dhuhr
            case .asr: asr
            case .maghrib: maghrib
            case .isha: isha
            }
        }
        set {
            switch prayer {
            case .fajr: fajr = newValue
            case .sunrise: sunrise = newValue
            case .dhuhr: dhuhr = newValue
            case .asr: asr = newValue
            case .maghrib: maghrib = newValue
            case .isha: isha = newValue
            }
        }
    }
}

struct CalculationConfig: Equatable, Sendable {
    var method: CalculationMethodOption = .muslimWorldLeague
    var madhab: MadhabOption = .shafi
    var fajrAngleOverride: Double?
    var ishaAngleOverride: Double?
    var offsets = PrayerOffsets()
}
