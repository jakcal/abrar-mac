import SwiftUI

struct MenuBarLabel: View {
    let schedule: PrayerSchedule
    let settings: AppSettings

    var body: some View {
        if let next = schedule.nextPrayer {
            let title = PrayerFormatting.menuBarTitle(next: next, now: schedule.now)
            if settings.highlightSoon, PrayerFormatting.isSoon(next.date, now: schedule.now, within: settings.highlightSoonMinutes) {
                // The menu bar draws text labels as templates, so colour only survives in a non-template image.
                Image(nsImage: Self.coloredImage(title))
                    .accessibilityLabel(title)
            } else {
                Text(title)
                    .monospacedDigit()
            }
        } else {
            Image(systemName: "moon.stars")
        }
    }

    private static func coloredImage(_ title: String) -> NSImage {
        let renderer = ImageRenderer(content: Text(title)
            .font(Font(NSFont.menuBarFont(ofSize: 0)))
            .monospacedDigit()
            .foregroundStyle(.red))
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        let image = renderer.nsImage ?? NSImage()
        image.isTemplate = false
        return image
    }
}
