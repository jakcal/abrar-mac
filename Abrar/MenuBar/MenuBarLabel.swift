import SwiftUI

struct MenuBarLabel: View {
    let schedule: PrayerSchedule

    var body: some View {
        if schedule.nextPrayer == nil {
            Image(systemName: "moon.stars")
        } else {
            Text(PrayerFormatting.menuBarTitle(next: schedule.nextPrayer, now: schedule.now))
                .monospacedDigit()
        }
    }
}
