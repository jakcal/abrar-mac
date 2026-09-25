import Foundation

enum LocationMode: String, Codable, CaseIterable, Sendable {
    case automatic, manual
}

struct AppSettings: Codable, Equatable, Sendable {
    var locationMode: LocationMode = .automatic
    var manualPlace: Place?
    var detectedPlace: Place?
    var method: CalculationMethodOption = .muslimWorldLeague
    var madhab: MadhabOption = .shafi
    var fajrAngleOverride: Double?
    var ishaAngleOverride: Double?
    var offsets = PrayerOffsets()
    var notifiedPrayers: Set<PrayerName> = Set(PrayerName.obligatory)
    var playFullAdhan = false
    var prayerSounds = PrayerSounds()
    var reciterID = Reciter.defaultID
    var quranFontSize: Double = 30
    var followRecitation = true
    var playbackRate: Double = 1

    init() {}

    var activePlace: Place? {
        locationMode == .manual ? manualPlace : detectedPlace
    }

    var calculationConfig: CalculationConfig {
        CalculationConfig(
            method: method,
            madhab: madhab,
            fajrAngleOverride: fajrAngleOverride,
            ishaAngleOverride: ishaAngleOverride,
            offsets: offsets
        )
    }

    private enum CodingKeys: String, CodingKey {
        case locationMode, manualPlace, detectedPlace, method, madhab
        case fajrAngleOverride, ishaAngleOverride, offsets, notifiedPrayers
        case playFullAdhan, prayerSounds, reciterID, quranFontSize, followRecitation, playbackRate
    }

    // Missing keys fall back to defaults so settings saved by older versions keep loading.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppSettings()
        locationMode = try c.decodeIfPresent(LocationMode.self, forKey: .locationMode) ?? d.locationMode
        manualPlace = try c.decodeIfPresent(Place.self, forKey: .manualPlace)
        detectedPlace = try c.decodeIfPresent(Place.self, forKey: .detectedPlace)
        method = try c.decodeIfPresent(CalculationMethodOption.self, forKey: .method) ?? d.method
        madhab = try c.decodeIfPresent(MadhabOption.self, forKey: .madhab) ?? d.madhab
        fajrAngleOverride = try c.decodeIfPresent(Double.self, forKey: .fajrAngleOverride)
        ishaAngleOverride = try c.decodeIfPresent(Double.self, forKey: .ishaAngleOverride)
        offsets = try c.decodeIfPresent(PrayerOffsets.self, forKey: .offsets) ?? d.offsets
        notifiedPrayers = try c.decodeIfPresent(Set<PrayerName>.self, forKey: .notifiedPrayers) ?? d.notifiedPrayers
        playFullAdhan = try c.decodeIfPresent(Bool.self, forKey: .playFullAdhan) ?? d.playFullAdhan
        prayerSounds = try c.decodeIfPresent(PrayerSounds.self, forKey: .prayerSounds) ?? d.prayerSounds
        reciterID = try c.decodeIfPresent(String.self, forKey: .reciterID) ?? d.reciterID
        quranFontSize = try c.decodeIfPresent(Double.self, forKey: .quranFontSize) ?? d.quranFontSize
        followRecitation = try c.decodeIfPresent(Bool.self, forKey: .followRecitation) ?? d.followRecitation
        playbackRate = try c.decodeIfPresent(Double.self, forKey: .playbackRate) ?? d.playbackRate
    }
}
