import Foundation
import UserNotifications

protocol NotificationScheduling: Sendable {
    func requestAuthorization() async -> Bool
    func reschedule(days: [PrayerDay], place: Place, enabled: Set<PrayerName>) async
    func scheduleTestNotification(after seconds: TimeInterval) async
}

struct UserNotificationScheduler: NotificationScheduling {
    static let identifierPrefix = "prayer."
    static let soundName = UNNotificationSoundName("adhan.caf")

    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func reschedule(days: [PrayerDay], place: Place, enabled: Set<PrayerName>) async {
        let center = UNUserNotificationCenter.current()
        let stale = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: stale)

        let now = Date()
        let times = days.flatMap(\.times).filter { enabled.contains($0.prayer) && $0.prayer.isObligatory && $0.date > now }
        for time in times {
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: time.date
            )
            let request = UNNotificationRequest(
                identifier: "\(Self.identifierPrefix)\(Int(time.date.timeIntervalSince1970)).\(time.prayer.rawValue)",
                content: content(for: time, place: place),
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            try? await center.add(request)
        }
    }

    func scheduleTestNotification(after seconds: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = "Abrar test"
        content.body = "Notifications are working."
        content.sound = UNNotificationSound(named: Self.soundName)
        let request = UNNotificationRequest(
            identifier: "test.\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    private func content(for time: PrayerTime, place: Place) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "\(time.prayer.displayName) · \(time.prayer.arabicName)"
        content.body = "It's time for \(time.prayer.displayName) in \(place.name) (\(PrayerFormatting.time(time.date, in: place.timeZone)))."
        content.sound = UNNotificationSound(named: Self.soundName)
        return content
    }
}

/// Shows prayer notifications even while Abrar is the active app.
final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate, Sendable {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
