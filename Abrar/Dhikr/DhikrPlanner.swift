import Foundation

/// A daily repeating reminder at a time of day.
struct DhikrReminderSlot: Equatable, Sendable {
    /// Minutes from midnight.
    let minute: Int
    let phrase: DhikrPhrase
}

struct AdhkarAlert: Equatable, Sendable {
    let session: AdhkarSession
    let date: Date
}

/// Everything the dhikr notifications need, worked out ahead of scheduling.
struct DhikrPlan: Equatable, Sendable {
    var reminders: [DhikrReminderSlot] = []
    var reminderSound = AlertSound.tone
    /// Morning and evening alerts follow the prayer times, so they're dated.
    var adhkar: [AdhkarAlert] = []
    /// The night alert repeats daily at this minute from midnight.
    var nightMinute: Int?
}

enum DhikrPlanner {
    /// macOS keeps at most 64 pending notifications per app. Prayers take 35 (5 a day, 7 days)
    /// and adhkar up to 5, which leaves room for these.
    static let maxReminders = 20
    static let adhkarDays = 2

    static func plan(reminders: DhikrReminders, adhkar: AdhkarSettings, days: [PrayerDay], now: Date) -> DhikrPlan {
        DhikrPlan(
            reminders: reminderSlots(reminders),
            reminderSound: reminders.sound,
            adhkar: adhkarAlerts(adhkar, days: days, now: now),
            nightMinute: adhkar.night ? adhkar.nightTime : nil
        )
    }

    static func reminderSlots(_ reminders: DhikrReminders) -> [DhikrReminderSlot] {
        let phrases = reminders.rotation
        guard reminders.isEnabled, !phrases.isEmpty else { return [] }
        return reminderMinutes(reminders).enumerated().map { index, minute in
            DhikrReminderSlot(minute: minute, phrase: phrases[index % phrases.count])
        }
    }

    /// Times of day from the start to the end of the window, inclusive, capped at `maxReminders`.
    static func reminderMinutes(_ reminders: DhikrReminders) -> [Int] {
        let interval = max(reminders.interval, 15)
        let end = reminders.end < reminders.start ? reminders.end + 24 * 60 : reminders.end
        return stride(from: reminders.start, through: end, by: interval)
            .prefix(maxReminders)
            .map { $0 % (24 * 60) }
    }

    static func adhkarAlerts(_ settings: AdhkarSettings, days: [PrayerDay], now: Date) -> [AdhkarAlert] {
        days.prefix(adhkarDays).flatMap { day -> [AdhkarAlert] in
            var alerts: [AdhkarAlert] = []
            if settings.morning, let fajr = day.time(for: .fajr) {
                alerts.append(AdhkarAlert(session: .morning, date: fajr.addingTimeInterval(Double(settings.morningDelay) * 60)))
            }
            if settings.evening, let asr = day.time(for: .asr) {
                alerts.append(AdhkarAlert(session: .evening, date: asr.addingTimeInterval(Double(settings.eveningDelay) * 60)))
            }
            return alerts
        }
        .filter { $0.date > now }
    }
}
