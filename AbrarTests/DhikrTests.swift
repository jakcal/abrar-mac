import Foundation
import Testing
@testable import Abrar

struct DhikrPlannerTests {
    private let base = Date(timeIntervalSince1970: 1_700_000_000)

    private func day(startingAt hours: Double) -> PrayerDay {
        let offsets: [(PrayerName, Double)] = [(.fajr, 5), (.sunrise, 6.5), (.dhuhr, 12), (.asr, 15), (.maghrib, 18), (.isha, 19.5)]
        return PrayerDay(times: offsets.map { PrayerTime(prayer: $0.0, date: base.addingTimeInterval((hours + $0.1) * 3600)) })
    }

    @Test func remindersOffByDefault() {
        #expect(DhikrPlanner.reminderSlots(DhikrReminders()).isEmpty)
    }

    @Test func remindersRotateThroughEnabledPhrases() {
        var reminders = DhikrReminders()
        reminders.isEnabled = true
        reminders.enabledPhrases = ["astaghfirullah", "alhamdulillah"]
        reminders.customPhrases = [CustomDhikr(text: "Ya Allah"), CustomDhikr(text: "Off", isEnabled: false)]
        reminders.start = 9 * 60
        reminders.end = 12 * 60
        reminders.interval = 60

        let slots = DhikrPlanner.reminderSlots(reminders)
        #expect(slots.map(\.minute) == [540, 600, 660, 720])
        #expect(slots.map(\.phrase.transliteration) == ["Astaghfirullah", "Alhamdulillah", "Ya Allah", "Astaghfirullah"])
    }

    @Test func reminderWindowCanCrossMidnight() {
        var reminders = DhikrReminders()
        reminders.start = 22 * 60
        reminders.end = 60
        reminders.interval = 90
        #expect(DhikrPlanner.reminderMinutes(reminders) == [1320, 1410, 60])
    }

    @Test func remindersAreCapped() {
        var reminders = DhikrReminders()
        reminders.start = 0
        reminders.end = 23 * 60
        reminders.interval = 30
        #expect(DhikrPlanner.reminderMinutes(reminders).count == DhikrPlanner.maxReminders)
    }

    @Test func noRemindersWithoutPhrases() {
        var reminders = DhikrReminders()
        reminders.isEnabled = true
        reminders.enabledPhrases = []
        #expect(DhikrPlanner.reminderSlots(reminders).isEmpty)
    }

    @Test func adhkarFollowFajrAndAsrForTwoDays() {
        var settings = AdhkarSettings()
        settings.morning = true
        settings.morningDelay = 30
        settings.evening = true
        settings.eveningDelay = 0
        let days = [day(startingAt: 0), day(startingAt: 24), day(startingAt: 48)]
        let now = base.addingTimeInterval(10 * 3600)

        let alerts = DhikrPlanner.adhkarAlerts(settings, days: days, now: now)
        #expect(alerts == [
            AdhkarAlert(session: .evening, date: base.addingTimeInterval(15 * 3600)),
            AdhkarAlert(session: .morning, date: base.addingTimeInterval(29.5 * 3600)),
            AdhkarAlert(session: .evening, date: base.addingTimeInterval(39 * 3600)),
        ])
    }

    @Test func nightRepeatsOnlyWhenEnabled() {
        var settings = AdhkarSettings()
        #expect(DhikrPlanner.plan(reminders: DhikrReminders(), adhkar: settings, days: [], now: base).nightMinute == nil)
        settings.night = true
        settings.nightTime = 23 * 60
        #expect(DhikrPlanner.plan(reminders: DhikrReminders(), adhkar: settings, days: [], now: base).nightMinute == 1380)
    }

    @Test func worstCaseFitsNotificationLimit() {
        var reminders = DhikrReminders()
        reminders.isEnabled = true
        reminders.start = 0
        reminders.end = 23 * 60
        reminders.interval = 30
        var adhkar = AdhkarSettings()
        adhkar.morning = true
        adhkar.evening = true
        adhkar.night = true
        let days = (0..<7).map { day(startingAt: Double($0) * 24) }
        let plan = DhikrPlanner.plan(reminders: reminders, adhkar: adhkar, days: days, now: base)
        let prayers = PrayerName.obligatory.count * 7
        #expect(prayers + plan.reminders.count + plan.adhkar.count + (plan.nightMinute == nil ? 0 : 1) <= 64)
    }

    @Test func currentSessionFollowsPrayers() {
        let times = day(startingAt: 0).times
        func at(_ hours: Double) -> AdhkarSession? {
            AdhkarSession.current(in: times, at: base.addingTimeInterval(hours * 3600))
        }
        #expect(at(3) == .night)
        #expect(at(7) == .morning)
        #expect(at(13) == nil)
        #expect(at(16) == .evening)
        #expect(at(21) == .night)
    }
}

struct DhikrSettingsTests {
    @Test func oldSettingsLoadWithDefaults() throws {
        let json = #"{"method":"egyptian","dhikrReminders":{"isEnabled":true}}"#
        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))
        #expect(settings.dhikrReminders.isEnabled)
        #expect(settings.dhikrReminders.interval == DhikrReminders().interval)
        #expect(settings.dhikrReminders.enabledPhrases == DhikrPhrase.defaultIDs)
        #expect(settings.adhkar == AdhkarSettings())
    }

    @Test func roundTrip() throws {
        let repository = GRDBSettingsRepository(database: try UserDatabase.inMemory())
        var settings = AppSettings()
        settings.dhikrReminders.isEnabled = true
        settings.dhikrReminders.interval = 120
        settings.dhikrReminders.sound = .silent
        settings.dhikrReminders.customPhrases = [CustomDhikr(text: "Ya Latif")]
        settings.adhkar.night = true
        settings.adhkar.nightTime = 23 * 60 + 15
        try repository.save(settings)
        #expect(try repository.load() == settings)
    }

    @Test func builtInPhraseIDsAreUnique() {
        #expect(Set(DhikrPhrase.builtIn.map(\.id)).count == DhikrPhrase.builtIn.count)
        #expect(DhikrPhrase.defaultIDs.isSubset(of: Set(DhikrPhrase.builtIn.map(\.id))))
    }
}

@MainActor
struct AdhkarModelTests {
    private let quran: QuranStore

    init() throws {
        quran = try GRDBQuranStore.bundled()
    }

    @Test func itemIDsAreUniquePerSession() {
        for session in AdhkarSession.allCases {
            let items = AdhkarCatalog.items(for: session)
            #expect(Set(items.map(\.id)).count == items.count)
            #expect(items.allSatisfy { $0.count > 0 })
        }
    }

    @Test func quranItemsResolveFromBundledText() {
        let model = AdhkarModel(quran: quran)
        for session in AdhkarSession.allCases {
            for item in AdhkarCatalog.items(for: session) {
                #expect(!model.arabic(for: item).isEmpty, "\(item.id)")
            }
        }
        let ikhlas = AdhkarCatalog.morning.first { $0.id == "qul112" }!
        #expect(model.arabic(for: ikhlas).hasPrefix("بِسْمِ"))
        #expect(model.arabic(for: ikhlas).contains("قُلْ هُوَ ٱللَّهُ أَحَدٌ"))
    }

    @Test func countingStopsAtTargetAndUndoes() {
        let model = AdhkarModel(quran: quran)
        model.session = .morning
        let item = AdhkarCatalog.morning.first { $0.count == 3 }!
        #expect(!model.tap(item))
        #expect(!model.tap(item))
        #expect(model.tap(item))
        #expect(!model.tap(item))
        #expect(model.count(of: item) == 3)
        #expect(model.isDone(item))

        model.undo(item)
        #expect(model.count(of: item) == 2)

        model.session = .evening
        #expect(model.count(of: item) == 0)
        #expect(model.count(of: item, in: .morning) == 2)

        model.session = .morning
        model.reset()
        #expect(model.count(of: item) == 0)
    }
}
