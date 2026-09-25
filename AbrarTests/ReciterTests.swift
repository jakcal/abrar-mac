import Foundation
import Testing
@testable import Abrar

struct ReciterTests {
    @Test func idsAreUnique() {
        #expect(Set(Reciter.all.map(\.id)).count == Reciter.all.count)
        #expect(Set(Reciter.all.map(\.qdcID)).count == Reciter.all.count)
    }

    @Test func buildsQuranicAudioURLs() throws {
        #expect(Reciter.with(id: "alafasy").remoteURL(forSurah: 1)?.absoluteString
            == "https://download.quranicaudio.com/qdc/mishari_al_afasy/murattal/1.mp3")
        #expect(Reciter.with(id: "shuraym").remoteURL(forSurah: 2)?.absoluteString
            == "https://download.quranicaudio.com/qdc/saud_ash-shuraym/murattal/002.mp3")
        for reciter in Reciter.all {
            let url = try #require(reciter.remoteURL(forSurah: 114))
            #expect(url.absoluteString.hasSuffix("/114.mp3"), "\(reciter.id)")
        }
    }

    @Test func unknownIDFallsBack() {
        #expect(Reciter.with(id: "nope") == Reciter.all[0])
    }
}

struct AyahTimingTests {
    private let sample = Data("""
        {"audio_files":[{"audio_url":"x","verse_timings":[
          {"verse_key":"1:2","timestamp_from":6090,"timestamp_to":11000},
          {"verse_key":"1:1","timestamp_from":0,"timestamp_to":6090},
          {"verse_key":"1:3","timestamp_from":11500,"timestamp_to":15000}
        ]}]}
        """.utf8)

    @Test func parsesQDCResponse() throws {
        let timings = try QDCTimingService.parse(sample)
        #expect(timings.ayahs.map(\.ayah) == [1, 2, 3])
        #expect(timings.start(of: 2) == 6.09)
    }

    @Test func findsAyahAtTime() throws {
        let timings = try QDCTimingService.parse(sample)
        #expect(timings.ayah(at: 0) == 1)
        #expect(timings.ayah(at: 6.1) == 2)
        #expect(timings.ayah(at: 11.2) == 2)
        #expect(timings.ayah(at: 20) == 3)
    }

    @Test func rejectsEmptyTimings() {
        #expect(throws: (any Error).self) {
            try QDCTimingService.parse(Data(#"{"audio_files":[]}"#.utf8))
        }
    }

    @Test func cacheRoundTrip() throws {
        let cache = GRDBTimingCache(database: try UserDatabase.inMemory())
        let timings = try QDCTimingService.parse(sample)
        #expect(try cache.timings(reciterID: "alafasy", surah: 1) == nil)
        try cache.store(timings, reciterID: "alafasy", surah: 1)
        #expect(try cache.timings(reciterID: "alafasy", surah: 1) == timings)
        #expect(try cache.timings(reciterID: "sudais", surah: 1) == nil)
    }

    @Test func serviceUsesCacheWithoutNetwork() async throws {
        let cache = GRDBTimingCache(database: try UserDatabase.inMemory())
        let timings = try QDCTimingService.parse(sample)
        try cache.store(timings, reciterID: "alafasy", surah: 1)
        let service = QDCTimingService(cache: cache)
        #expect(try await service.timings(reciter: Reciter.with(id: "alafasy"), surah: 1) == timings)
    }
}
