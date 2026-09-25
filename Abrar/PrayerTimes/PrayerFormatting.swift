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

    /// Whole hours and minutes left, rounded up like `countdown`.
    static func remaining(from now: Date, to date: Date) -> (hours: Int, minutes: Int) {
        let minutes = max(0, Int((date.timeIntervalSince(now) / 60).rounded(.up)))
        return (minutes / 60, minutes % 60)
    }

    /// "1 hour, 24 minutes", for VoiceOver.
    static func spokenCountdown(from now: Date, to date: Date) -> String {
        let left = remaining(from: now, to: date)
        return Duration.seconds(left.hours * 3600 + left.minutes * 60)
            .formatted(.units(allowed: [.hours, .minutes], width: .wide))
    }

    static func menuBarTitle(next: PrayerTime?, now: Date) -> String {
        guard let next else { return "Abrar" }
        return "\(next.prayer.displayName) \(countdown(from: now, to: next.date))"
    }
}
