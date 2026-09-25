import Foundation

enum AlertSound: String, Codable, CaseIterable, Identifiable, Sendable {
    case adhan, tone, silent

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .adhan: "Adhan"
        case .tone: "Notification tone"
        case .silent: "Silent"
        }
    }

    var symbolName: String {
        switch self {
        case .adhan: "speaker.wave.2.fill"
        case .tone: "bell.fill"
        case .silent: "speaker.slash.fill"
        }
    }
}

/// Alert sound for each obligatory prayer.
struct PrayerSounds: Codable, Equatable, Sendable {
    var fajr = AlertSound.adhan
    var dhuhr = AlertSound.adhan
    var asr = AlertSound.adhan
    var maghrib = AlertSound.adhan
    var isha = AlertSound.adhan

    subscript(prayer: PrayerName) -> AlertSound {
        get {
            switch prayer {
            case .fajr: fajr
            case .sunrise: .silent
            case .dhuhr: dhuhr
            case .asr: asr
            case .maghrib: maghrib
            case .isha: isha
            }
        }
        set {
            switch prayer {
            case .fajr: fajr = newValue
            case .sunrise: break
            case .dhuhr: dhuhr = newValue
            case .asr: asr = newValue
            case .maghrib: maghrib = newValue
            case .isha: isha = newValue
            }
        }
    }
}
