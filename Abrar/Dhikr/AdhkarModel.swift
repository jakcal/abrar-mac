import Foundation
import Observation

/// The adhkar window's state: which set is shown and how far through each one the user is today.
@MainActor
@Observable
final class AdhkarModel {
    var session: AdhkarSession = .morning
    private(set) var counts: [String: Int] = [:]

    @ObservationIgnored private let quran: QuranStore
    @ObservationIgnored private var arabicCache: [AdhkarItem.Content: String] = [:]

    init(quran: QuranStore) {
        self.quran = quran
    }

    var items: [AdhkarItem] { AdhkarCatalog.items(for: session) }

    func arabic(for item: AdhkarItem) -> String {
        if let cached = arabicCache[item.text] { return cached }
        let text: String
        switch item.text {
        case .arabic(let value):
            text = value
        case let .quran(surah, range, bismillah):
            let ayahs = ((try? quran.ayahs(inSurah: surah)) ?? []).filter { range.contains($0.number) }
            let body = ayahs.map { "\($0.text) \u{06DD}\(QuranFont.arabicDigits($0.number))" }.joined(separator: " ")
            let opening = bismillah ? ((try? quran.surah(id: surah))?.bismillah ?? "") : ""
            text = opening.isEmpty ? body : "\(opening)\n\(body)"
        }
        arabicCache[item.text] = text
        return text
    }

    func count(of item: AdhkarItem) -> Int {
        count(of: item, in: session)
    }

    func count(of item: AdhkarItem, in session: AdhkarSession) -> Int {
        counts[key(item, in: session)] ?? 0
    }

    func isDone(_ item: AdhkarItem) -> Bool {
        count(of: item) >= item.count
    }

    /// Counts one recitation; returns true when that completes the item.
    @discardableResult
    func tap(_ item: AdhkarItem) -> Bool {
        let current = count(of: item)
        guard current < item.count else { return false }
        let today = dayStamp
        counts = counts.filter { $0.key.hasPrefix("\(today).") }
        counts[key(item)] = current + 1
        return current + 1 == item.count
    }

    func undo(_ item: AdhkarItem) {
        counts[key(item)] = max(0, count(of: item) - 1)
    }

    func reset() {
        for item in items {
            counts[key(item)] = nil
        }
    }

    var nextItem: AdhkarItem? {
        items.first { !isDone($0) }
    }

    func completedCount(in session: AdhkarSession) -> Int {
        AdhkarCatalog.items(for: session).filter { count(of: $0, in: session) >= $0.count }.count
    }

    /// Keyed by day so progress starts over each morning.
    private func key(_ item: AdhkarItem, in session: AdhkarSession? = nil) -> String {
        "\(dayStamp).\((session ?? self.session).rawValue).\(item.id)"
    }

    private var dayStamp: String {
        let day = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return "\(day.year ?? 0)-\(day.month ?? 0)-\(day.day ?? 0)"
    }
}
