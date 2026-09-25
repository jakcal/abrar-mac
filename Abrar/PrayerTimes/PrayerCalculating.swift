import Foundation

struct PrayerTime: Identifiable, Hashable, Sendable {
    let prayer: PrayerName
    let date: Date

    var id: String { "\(prayer.rawValue)-\(Int(date.timeIntervalSince1970))" }
}

struct PrayerDay: Hashable, Sendable {
    let times: [PrayerTime]

    func time(for prayer: PrayerName) -> Date? {
        times.first { $0.prayer == prayer }?.date
    }
}

protocol PrayerCalculating: Sendable {
    /// `day` is a calendar date (year, month, day) local to `place`.
    func prayerDay(on day: DateComponents, place: Place, config: CalculationConfig) -> PrayerDay?
}

extension PrayerCalculating {
    func prayerDays(startingAt date: Date, count: Int, place: Place, config: CalculationConfig) -> [PrayerDay] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = place.timeZone
        return (0..<count).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: date) else { return nil }
            let components = calendar.dateComponents([.year, .month, .day], from: day)
            return prayerDay(on: components, place: place, config: config)
        }
    }
}
