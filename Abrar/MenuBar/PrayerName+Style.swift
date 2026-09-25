import SwiftUI

extension PrayerName {
    var symbolName: String {
        switch self {
        case .fajr: "sun.horizon"
        case .sunrise: "sunrise"
        case .dhuhr: "sun.max"
        case .asr: "sun.min"
        case .maghrib: "sunset"
        case .isha: "moon.stars"
        }
    }

    /// Sky colours at this time of day, top to bottom.
    var sky: [Color] {
        switch self {
        case .fajr: [Color(red: 0.33, green: 0.36, blue: 0.72), Color(red: 0.93, green: 0.58, blue: 0.62)]
        case .sunrise: [Color(red: 0.98, green: 0.70, blue: 0.45), Color(red: 0.55, green: 0.74, blue: 0.95)]
        case .dhuhr: [Color(red: 0.30, green: 0.62, blue: 0.96), Color(red: 0.56, green: 0.84, blue: 0.96)]
        case .asr: [Color(red: 0.96, green: 0.70, blue: 0.32), Color(red: 0.88, green: 0.52, blue: 0.36)]
        case .maghrib: [Color(red: 0.96, green: 0.48, blue: 0.34), Color(red: 0.52, green: 0.30, blue: 0.62)]
        case .isha: [Color(red: 0.16, green: 0.20, blue: 0.46), Color(red: 0.38, green: 0.27, blue: 0.58)]
        }
    }
}
