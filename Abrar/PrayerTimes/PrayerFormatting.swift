import Foundation

enum PrayerFormatting {
    static func time(_ date: Date, in timeZone: TimeZone) -> String {
        var style = Date.FormatStyle(date: .omitted, time: .shortened)
        style.timeZone = timeZone
        return date.formatted(style)
    }

    /// "1:24" for 1 h 24 min. Rounds up so the countdown reaches "0:00" exactly at the prayer time.
    static func countdown(from now: Date, to date: Date) -> String {
        let minutes = max(0, Int((date.timeIntervalSince(now) / 60).rounded(.up)))
        return String(format: "%d:%02d", minutes / 60, minutes % 60)
    }

    static func menuBarTitle(next: PrayerTime?, now: Date) -> String {
        guard let next else { return "Abrar" }
        return "\(next.prayer.displayName) \(countdown(from: now, to: next.date))"
    }
}
