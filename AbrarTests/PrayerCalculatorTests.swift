import Foundation
import Testing
@testable import Abrar

struct PrayerCalculatorTests {
    private let calculator = AdhanPrayerCalculator()
    private let casablanca = Place(
        name: "Casablanca", country: "Morocco",
        latitude: 33.5731, longitude: -7.5898, timeZoneID: "Africa/Casablanca"
    )
    private let day = DateComponents(year: 2026, month: 9, day: 25)

    private func times(_ config: CalculationConfig) throws -> [PrayerName: String] {
        let prayerDay = try #require(calculator.prayerDay(on: day, place: casablanca, config: config))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        // Habous publishes this timetable in UTC+0. A fixed offset keeps the test independent of
        // the machine's tz database (older ones still put Casablanca at UTC+1).
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return Dictionary(uniqueKeysWithValues: prayerDay.times.map { ($0.prayer, formatter.string(from: $0.date)) })
    }

    /// Reference: habous.gov.ma timetable for Casablanca, 25 Sep 2026.
    @Test func moroccoPresetMatchesHabousTimetable() throws {
        let result = try times(CalculationConfig(method: .morocco))
        #expect(result == [
            .fajr: "04:52", .sunrise: "06:17", .dhuhr: "12:27",
            .asr: "15:48", .maghrib: "18:28", .isha: "19:41",
        ])
    }

    @Test func timesAreWholeMinutes() throws {
        for method in CalculationMethodOption.allCases {
            let prayerDay = try #require(calculator.prayerDay(on: day, place: casablanca, config: CalculationConfig(method: method)))
            #expect(prayerDay.times.allSatisfy { $0.date.timeIntervalSince1970.truncatingRemainder(dividingBy: 60) == 0 })
        }
    }

    @Test func returnsSixOrderedTimes() throws {
        let prayerDay = try #require(calculator.prayerDay(on: day, place: casablanca, config: CalculationConfig()))
        #expect(prayerDay.times.map(\.prayer) == PrayerName.allCases)
        #expect(prayerDay.times.map(\.date) == prayerDay.times.map(\.date).sorted())
    }

    @Test func hanafiAsrIsLater() throws {
        let shafi = try #require(calculator.prayerDay(on: day, place: casablanca, config: CalculationConfig()))
        let hanafi = try #require(calculator.prayerDay(on: day, place: casablanca, config: CalculationConfig(madhab: .hanafi)))
        let difference = try #require(hanafi.time(for: .asr)).timeIntervalSince(try #require(shafi.time(for: .asr)))
        #expect(difference > 30 * 60)
    }

    @Test func minuteOffsetsShiftOnlyTheirPrayer() throws {
        var offsets = PrayerOffsets()
        offsets[.maghrib] = 3
        let base = try #require(calculator.prayerDay(on: day, place: casablanca, config: CalculationConfig()))
        let adjusted = try #require(calculator.prayerDay(on: day, place: casablanca, config: CalculationConfig(offsets: offsets)))
        for prayer in PrayerName.allCases {
            let delta = try #require(adjusted.time(for: prayer)).timeIntervalSince(try #require(base.time(for: prayer)))
            #expect(delta == (prayer == .maghrib ? 180 : 0), "\(prayer)")
        }
    }

    @Test func angleOverridesReplacePresetAngles() {
        let params = calculator.parameters(for: CalculationConfig(
            method: .ummAlQura, fajrAngleOverride: 16, ishaAngleOverride: 15
        ))
        #expect(params.fajrAngle == 16)
        #expect(params.ishaAngle == 15)
        #expect(params.ishaInterval == 0)
    }

    @Test func everyPresetProducesTimes() {
        for method in CalculationMethodOption.allCases {
            #expect(calculator.prayerDay(on: day, place: casablanca, config: CalculationConfig(method: method)) != nil, "\(method)")
        }
    }

    @Test func countdownRoundsUp() {
        let now = Date(timeIntervalSince1970: 0)
        #expect(PrayerFormatting.countdown(from: now, to: now.addingTimeInterval(84 * 60)) == "1:24")
        #expect(PrayerFormatting.countdown(from: now, to: now.addingTimeInterval(30)) == "0:01")
        #expect(PrayerFormatting.countdown(from: now, to: now) == "0:00")
    }
}
