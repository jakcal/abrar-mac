import Foundation

/// How far a reciter's full-Quran download has got.
struct BulkDownloadProgress: Equatable, Sendable {
    static let surahCount = 114

    let savedCount: Int
    let savedBytes: Int64
    let inFlightCount: Int
    let failedCount: Int
    /// Saved surahs plus partial progress of those downloading, out of 114.
    let fraction: Double
    let isRunning: Bool

    var remaining: Int { Self.surahCount - savedCount }
    var isComplete: Bool { savedCount >= Self.surahCount }

    init(sizes: [Int: Int64], states: [Int: DownloadState], isBulkRun: Bool) {
        var inFlight = 0
        var failed = 0
        var partial = 0.0
        for (surah, state) in states where sizes[surah] == nil {
            switch state {
            case let .downloading(value):
                inFlight += 1
                partial += min(1, max(0, value))
            case .failed:
                failed += 1
            case .notDownloaded, .downloaded:
                break
            }
        }
        savedCount = sizes.count
        savedBytes = sizes.values.reduce(0, +)
        inFlightCount = inFlight
        failedCount = failed
        fraction = min(1, (Double(sizes.count) + partial) / Double(Self.surahCount))
        isRunning = isBulkRun && inFlight > 0
    }
}
