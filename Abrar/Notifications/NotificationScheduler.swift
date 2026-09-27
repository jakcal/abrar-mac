import Foundation
import UserNotifications

/// A sample of an alert, sent right away so the user can see and hear it.
enum TestAlert: Sendable {
    case reminder(DhikrPhrase, sound: AlertSound)
    case adhkar(AdhkarSession)
}

protocol NotificationScheduling: Sendable {
    func requestAuthorization() async -> Bool
    func reschedule(days: [PrayerDay], place: Place, enabled: Set<PrayerName>, sounds: PrayerSounds, adhan: AdhanVoice) async
    func reschedule(dhikr plan: DhikrPlan) async
    func send(_ test: TestAlert) async
    func scheduleTestNotification(after seconds: TimeInterval) async
}

struct UserNotificationScheduler: NotificationScheduling {
    static let identifierPrefix = "prayer."
    static let dhikrPrefix = "dhikr."
    static let adhkarKey = "adhkar"

    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func reschedule(days: [PrayerDay], place: Place, enabled: Set<PrayerName>, sounds: PrayerSounds, adhan: AdhanVoice) async {
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
                content: content(for: time, place: place, sound: sounds[time.prayer], adhan: adhan),
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            try? await center.add(request)
        }
    }

    func reschedule(dhikr plan: DhikrPlan) async {
        let center = UNUserNotificationCenter.current()
        let stale = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.dhikrPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: stale)

        for slot in plan.reminders {
            try? await center.add(UNNotificationRequest(
                identifier: "\(Self.dhikrPrefix)reminder.\(slot.minute)",
                content: reminderContent(slot.phrase, sound: plan.reminderSound),
                trigger: UNCalendarNotificationTrigger(dateMatching: Self.timeOfDay(slot.minute), repeats: true)
            ))
        }
        for alert in plan.adhkar {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: alert.date)
            try? await center.add(UNNotificationRequest(
                identifier: "\(Self.dhikrPrefix)\(alert.session.rawValue).\(Int(alert.date.timeIntervalSince1970))",
                content: adhkarContent(alert.session),
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            ))
        }
        if let minute = plan.nightMinute {
            try? await center.add(UNNotificationRequest(
                identifier: "\(Self.dhikrPrefix)night",
                content: adhkarContent(.night),
                trigger: UNCalendarNotificationTrigger(dateMatching: Self.timeOfDay(minute), repeats: true)
            ))
        }
    }

    private static func timeOfDay(_ minute: Int) -> DateComponents {
        DateComponents(hour: minute / 60, minute: minute % 60)
    }

    private func reminderContent(_ phrase: DhikrPhrase, sound: AlertSound) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = phrase.transliteration
        content.body = [phrase.arabic, phrase.meaning].filter { !$0.isEmpty }.joined(separator: " · ")
        content.sound = sound == .silent ? nil : .default
        return content
    }

    private func adhkarContent(_ session: AdhkarSession) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "\(session.title) · \(session.arabicTitle)"
        content.body = "Click to open the \(session.title.lowercased()) and count as you go."
        content.sound = .default
        content.userInfo = [Self.adhkarKey: session.rawValue]
        return content
    }

    func send(_ test: TestAlert) async {
        let content = switch test {
        case let .reminder(phrase, sound): reminderContent(phrase, sound: sound)
        case let .adhkar(session): adhkarContent(session)
        }
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(
            identifier: "test.\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        ))
    }

    func scheduleTestNotification(after seconds: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = "Abrar test"
        content.body = "Notifications are working."
        content.sound = UNNotificationSound(named: UNNotificationSoundName(AdhanVoice.builtIn[0].notificationSound))
        let request = UNNotificationRequest(
            identifier: "test.\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    private func content(for time: PrayerTime, place: Place, sound: AlertSound, adhan: AdhanVoice) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "\(time.prayer.displayName) · \(time.prayer.arabicName)"
        content.body = "It's time for \(time.prayer.displayName) in \(place.name) (\(PrayerFormatting.time(time.date, in: place.timeZone)))."
        switch sound {
        case .adhan: content.sound = UNNotificationSound(named: UNNotificationSoundName(adhan.notificationSound))
        case .tone: content.sound = .default
        case .silent: content.sound = nil
        }
        return content
    }
}

/// Shows notifications even while Abrar is the active app, and opens the adhkar ones when clicked.
final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate, Sendable {
    private let openAdhkar: @MainActor @Sendable (AdhkarSession) -> Void

    init(openAdhkar: @escaping @MainActor @Sendable (AdhkarSession) -> Void) {
        self.openAdhkar = openAdhkar
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier,
              let raw = response.notification.request.content.userInfo[UserNotificationScheduler.adhkarKey] as? String,
              let session = AdhkarSession(rawValue: raw) else { return }
        await openAdhkar(session)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
