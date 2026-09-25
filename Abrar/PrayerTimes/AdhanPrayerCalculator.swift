import Adhan
import Foundation

struct AdhanPrayerCalculator: PrayerCalculating {
    func prayerDay(on day: DateComponents, place: Place, config: CalculationConfig) -> PrayerDay? {
        let coordinates = Coordinates(latitude: place.latitude, longitude: place.longitude)
        var params = parameters(for: config)
        let presetRounding = params.rounding
        params.rounding = .none
        guard let times = PrayerTimes(coordinates: coordinates, date: day, calculationParameters: params) else {
            return nil
        }

        let raw: [(PrayerName, Date)] = [
            (.fajr, times.fajr), (.sunrise, times.sunrise), (.dhuhr, times.dhuhr),
            (.asr, times.asr), (.maghrib, times.maghrib), (.isha, times.isha),
        ]
        return PrayerDay(times: raw.map { prayer, date in
            PrayerTime(prayer: prayer, date: Self.round(date, rule(for: prayer, method: config.method, preset: presetRounding)))
        })
    }

    func parameters(for config: CalculationConfig) -> CalculationParameters {
        var (params, presetOffsets) = preset(for: config.method)
        params.madhab = config.madhab == .hanafi ? .hanafi : .shafi
        if let fajr = config.fajrAngleOverride {
            params.fajrAngle = fajr
        }
        if let isha = config.ishaAngleOverride {
            params.ishaAngle = isha
            params.ishaInterval = 0
        }
        let offsets = config.offsets
        params.adjustments = PrayerAdjustments(
            fajr: presetOffsets.fajr + offsets.fajr,
            sunrise: presetOffsets.sunrise + offsets.sunrise,
            dhuhr: presetOffsets.dhuhr + offsets.dhuhr,
            asr: presetOffsets.asr + offsets.asr,
            maghrib: presetOffsets.maghrib + offsets.maghrib,
            isha: presetOffsets.isha + offsets.isha
        )
        return params
    }

    private func preset(for method: CalculationMethodOption) -> (CalculationParameters, PrayerOffsets) {
        switch method {
        case .muslimWorldLeague: (CalculationMethod.muslimWorldLeague.params, PrayerOffsets())
        case .egyptian: (CalculationMethod.egyptian.params, PrayerOffsets())
        case .karachi: (CalculationMethod.karachi.params, PrayerOffsets())
        case .ummAlQura: (CalculationMethod.ummAlQura.params, PrayerOffsets())
        case .dubai: (CalculationMethod.dubai.params, PrayerOffsets())
        case .moonsightingCommittee: (CalculationMethod.moonsightingCommittee.params, PrayerOffsets())
        case .northAmerica: (CalculationMethod.northAmerica.params, PrayerOffsets())
        case .kuwait: (CalculationMethod.kuwait.params, PrayerOffsets())
        case .qatar: (CalculationMethod.qatar.params, PrayerOffsets())
        case .singapore: (CalculationMethod.singapore.params, PrayerOffsets())
        case .tehran: (CalculationMethod.tehran.params, PrayerOffsets())
        case .turkey: (CalculationMethod.turkey.params, PrayerOffsets())
        case .morocco:
            // Calibrated against the Ministry of Habous published tables.
            (Self.customParams(fajr: 19, isha: 17), PrayerOffsets(sunrise: -3, dhuhr: 5, asr: 1, maghrib: 5))
        case .other:
            (Self.customParams(fajr: 18, isha: 17), PrayerOffsets())
        }
    }

    private enum MinuteRounding {
        case nearest, up, down
    }

    private func rule(for prayer: PrayerName, method: CalculationMethodOption, preset: Rounding) -> MinuteRounding {
        // Habous rounds Fajr and Sunrise down, everything else to the nearest minute.
        if method == .morocco, prayer == .fajr || prayer == .sunrise {
            return .down
        }
        return preset == .up ? .up : .nearest
    }

    private static func round(_ date: Date, _ rule: MinuteRounding) -> Date {
        let minutes = date.timeIntervalSince1970 / 60
        let rounded: Double = switch rule {
        case .nearest: minutes.rounded()
        case .up: minutes.rounded(.up)
        case .down: minutes.rounded(.down)
        }
        return Date(timeIntervalSince1970: rounded * 60)
    }

    private static func customParams(fajr: Double, isha: Double) -> CalculationParameters {
        var params = CalculationMethod.other.params
        params.fajrAngle = fajr
        params.ishaAngle = isha
        return params
    }
}
