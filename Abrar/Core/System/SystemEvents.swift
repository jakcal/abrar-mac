import AppKit

/// Calls `handler` when the day, time zone or clock changes, or the Mac wakes from sleep.
@MainActor
final class SystemEvents {
    private var tokens: [(NotificationCenter, NSObjectProtocol)] = []

    init(handler: @escaping @MainActor @Sendable () -> Void) {
        let observe = { (center: NotificationCenter, name: Notification.Name) in
            let token = center.addObserver(forName: name, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { handler() }
            }
            self.tokens.append((center, token))
        }
        observe(.default, .NSCalendarDayChanged)
        observe(.default, .NSSystemTimeZoneDidChange)
        observe(.default, .NSSystemClockDidChange)
        observe(NSWorkspace.shared.notificationCenter, NSWorkspace.didWakeNotification)
    }

    func stop() {
        for (center, token) in tokens {
            center.removeObserver(token)
        }
        tokens.removeAll()
    }
}
