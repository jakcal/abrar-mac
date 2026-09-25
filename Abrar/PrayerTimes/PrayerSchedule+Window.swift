import Foundation

extension PrayerSchedule {
    /// From the latest prayer (or sunrise) before now until the next obligatory prayer.
    var nextPrayerWindow: DateInterval? {
        guard let next = nextPrayer else { return nil }
        return Self.window(until: next, today: today?.times ?? [], now: now)
    }

    /// Before Fajr the previous prayer is yesterday's Isha, approximated from today's.
    nonisolated static func window(until next: PrayerTime, today: [PrayerTime], now: Date) -> DateInterval? {
        let previous = today.last { $0.date <= now }?.date
            ?? today.last { $0.prayer == .isha }?.date.addingTimeInterval(-86_400)
        guard let previous, previous < next.date else { return nil }
        return DateInterval(start: previous, end: next.date)
    }

    nonisolated static func progress(of window: DateInterval, at now: Date) -> Double {
        guard window.duration > 0 else { return 0 }
        return min(1, max(0, now.timeIntervalSince(window.start) / window.duration))
    }
}
