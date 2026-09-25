import Foundation
import Testing
@testable import Abrar

struct BulkDownloadProgressTests {
    @Test func startsEmpty() {
        let progress = BulkDownloadProgress(sizes: [:], states: [:], isBulkRun: false)
        #expect(progress.savedCount == 0)
        #expect(progress.remaining == 114)
        #expect(!progress.isRunning)
        #expect(!progress.isComplete)
        #expect(progress.fraction == 0)
    }

    @Test func countsSavedInFlightAndFailed() {
        let progress = BulkDownloadProgress(
            sizes: [1: 100, 2: 200],
            states: [1: .downloaded(100), 3: .downloading(0.5), 4: .downloading(0.5), 5: .failed("x"), 6: .notDownloaded],
            isBulkRun: true
        )
        #expect(progress.savedCount == 2)
        #expect(progress.savedBytes == 300)
        #expect(progress.inFlightCount == 2)
        #expect(progress.failedCount == 1)
        #expect(progress.remaining == 112)
        #expect(progress.isRunning)
        #expect(abs(progress.fraction - 3.0 / 114) < 0.0001)
    }

    @Test func notRunningWithoutBulkRunOrInFlight() {
        #expect(!BulkDownloadProgress(sizes: [:], states: [1: .downloading(0.2)], isBulkRun: false).isRunning)
        #expect(!BulkDownloadProgress(sizes: [:], states: [1: .failed("x")], isBulkRun: true).isRunning)
    }

    @Test func completeWhenAllSaved() {
        let sizes = Dictionary(uniqueKeysWithValues: (1...114).map { ($0, Int64(10)) })
        let progress = BulkDownloadProgress(sizes: sizes, states: [:], isBulkRun: false)
        #expect(progress.isComplete)
        #expect(progress.remaining == 0)
        #expect(progress.fraction == 1)
        #expect(progress.savedBytes == 1140)
    }
}

struct PrayerWindowTests {
    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    private func time(_ prayer: PrayerName, hours: Double) -> PrayerTime {
        PrayerTime(prayer: prayer, date: base.addingTimeInterval(hours * 3600))
    }

    private var day: [PrayerTime] {
        [time(.fajr, hours: 5), time(.sunrise, hours: 6.5), time(.dhuhr, hours: 12),
         time(.asr, hours: 15), time(.maghrib, hours: 18), time(.isha, hours: 19.5)]
    }

    @Test func spansFromLatestTimeToNext() throws {
        let now = base.addingTimeInterval(13 * 3600)
        let window = try #require(PrayerSchedule.window(until: day[3], today: day, now: now))
        #expect(window.start == day[2].date)
        #expect(window.end == day[3].date)
        #expect(abs(PrayerSchedule.progress(of: window, at: now) - 1.0 / 3) < 0.0001)
    }

    @Test func beforeFajrStartsAtYesterdaysIsha() throws {
        let now = base.addingTimeInterval(2 * 3600)
        let window = try #require(PrayerSchedule.window(until: day[0], today: day, now: now))
        #expect(window.start == day[5].date.addingTimeInterval(-86_400))
    }

    @Test func progressIsClamped() {
        let window = DateInterval(start: base, duration: 100)
        #expect(PrayerSchedule.progress(of: window, at: base.addingTimeInterval(-10)) == 0)
        #expect(PrayerSchedule.progress(of: window, at: base.addingTimeInterval(500)) == 1)
    }

    @Test func remainingRoundsUp() {
        let left = PrayerFormatting.remaining(from: base, to: base.addingTimeInterval(3600 + 23 * 60 + 5))
        #expect(left.hours == 1)
        #expect(left.minutes == 24)
    }
}
