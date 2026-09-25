import Foundation
import Observation

@MainActor
@Observable
final class PrayerSchedule {
    private(set) var place: Place?
    private(set) var today: PrayerDay?
    private(set) var tomorrow: PrayerDay?
    private(set) var now = Date()

    @ObservationIgnored var onPrayerTime: (@MainActor (PrayerTime) -> Void)?
    @ObservationIgnored private let calculator: PrayerCalculating
    @ObservationIgnored private var config = CalculationConfig()
    @ObservationIgnored private var ticker: Task<Void, Never>?
    @ObservationIgnored private var calculatedDay: DateComponents?

    init(calculator: PrayerCalculating) {
        self.calculator = calculator
    }

    func update(place: Place?, config: CalculationConfig) {
        self.place = place
        self.config = config
        recalculate()
    }

    func recalculate() {
        now = Date()
        guard let place else {
            today = nil
            tomorrow = nil
            calculatedDay = nil
            return
        }
        let days = calculator.prayerDays(startingAt: now, count: 2, place: place, config: config)
        today = days.first
        tomorrow = days.dropFirst().first
        calculatedDay = dayComponents(for: now)
    }

    func upcomingDays(_ count: Int) -> [PrayerDay] {
        guard let place else { return [] }
        return calculator.prayerDays(startingAt: Date(), count: count, place: place, config: config)
    }

    var nextPrayer: PrayerTime? {
        let upcoming = (today?.times ?? []) + (tomorrow?.times ?? [])
        return upcoming.first { $0.prayer.isObligatory && $0.date > now }
    }

    var currentPrayer: PrayerTime? {
        today?.times.last { $0.date <= now }
    }

    func start() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                let seconds = 60 - Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 60)
                try? await Task.sleep(for: .seconds(seconds + 0.05))
                self?.tick()
            }
        }
    }

    private func tick() {
        let previous = now
        now = Date()
        if dayComponents(for: now) != calculatedDay {
            recalculate()
        }
        // Skip prayers missed while asleep; only announce ones that just started.
        let started = (today?.times ?? []).filter {
            $0.prayer.isObligatory && $0.date > previous && $0.date <= now && now.timeIntervalSince($0.date) < 90
        }
        started.forEach { onPrayerTime?($0) }
    }

    private func dayComponents(for date: Date) -> DateComponents? {
        guard let place else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = place.timeZone
        return calendar.dateComponents([.year, .month, .day], from: date)
    }
}
