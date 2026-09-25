import Foundation

struct AyahTiming: Codable, Equatable, Sendable {
    let ayah: Int
    /// Seconds from the start of the surah file.
    let start: Double
    let end: Double
}

struct SurahTimings: Codable, Equatable, Sendable {
    let ayahs: [AyahTiming]

    /// The ayah being recited at `seconds`, or the last one that started before it (covers gaps between ayahs).
    func ayah(at seconds: Double) -> Int? {
        ayahs.last { $0.start <= seconds }?.ayah
    }

    func start(of ayah: Int) -> Double? {
        ayahs.first { $0.ayah == ayah }?.start
    }
}

protocol AyahTimingProviding: Sendable {
    func timings(reciter: Reciter, surah: Int) async throws -> SurahTimings
}

/// Fetches timings from quran.com's QDC audio API and caches them in the user database for offline use.
struct QDCTimingService: AyahTimingProviding {
    let cache: TimingCache
    var session: URLSession = .shared

    func timings(reciter: Reciter, surah: Int) async throws -> SurahTimings {
        if let cached = try? cache.timings(reciterID: reciter.id, surah: surah) {
            return cached
        }
        guard let url = URL(string: "https://api.qurancdn.com/api/qdc/audio/reciters/\(reciter.qdcID)/audio_files?chapter=\(surah)&segments=true") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        let timings = try Self.parse(data)
        try? cache.store(timings, reciterID: reciter.id, surah: surah)
        return timings
    }

    static func parse(_ data: Data) throws -> SurahTimings {
        struct Response: Decodable {
            struct File: Decodable { let verse_timings: [Timing]? }
            struct Timing: Decodable {
                let verse_key: String
                let timestamp_from: Double
                let timestamp_to: Double
            }
            let audio_files: [File]
        }
        let timings = try JSONDecoder().decode(Response.self, from: data).audio_files.first?.verse_timings ?? []
        let ayahs = timings.compactMap { timing -> AyahTiming? in
            guard let ayah = timing.verse_key.split(separator: ":").last.flatMap({ Int($0) }) else { return nil }
            return AyahTiming(ayah: ayah, start: timing.timestamp_from / 1000, end: timing.timestamp_to / 1000)
        }
        guard !ayahs.isEmpty else { throw URLError(.cannotParseResponse) }
        return SurahTimings(ayahs: ayahs.sorted { $0.start < $1.start })
    }
}
