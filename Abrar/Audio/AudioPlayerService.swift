import AVFoundation
import Observation

@MainActor
@Observable
final class AudioPlayerService {
    private(set) var surah: Surah?
    private(set) var reciter: Reciter
    private(set) var isPlaying = false
    private(set) var isBuffering = false
    private(set) var isLocalFile = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0
    private(set) var errorMessage: String?
    /// Ayah being recited, when timings for the current file are available.
    private(set) var currentAyah: Int?
    private(set) var rate: Double = 1
    var sleepTimer: SleepTimer?

    @ObservationIgnored let player = AVPlayer()
    @ObservationIgnored let positions: ListeningPositionStore
    @ObservationIgnored var sleepTask: Task<Void, Never>?
    @ObservationIgnored private let storage: AudioStorage
    @ObservationIgnored private let quran: QuranStore
    @ObservationIgnored private let timingProvider: AyahTimingProviding
    @ObservationIgnored private var timings: SurahTimings?
    @ObservationIgnored private var timingTask: Task<SurahTimings?, Never>?
    @ObservationIgnored private var startTask: Task<Void, Never>?
    @ObservationIgnored var nowPlaying: NowPlayingController?
    @ObservationIgnored var timeObserver: Any?
    @ObservationIgnored var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var endObserver: NSObjectProtocol?
    @ObservationIgnored var lastSavedTime: Double = 0

    init(storage: AudioStorage, quran: QuranStore, timings: AyahTimingProviding,
         positions: ListeningPositionStore, reciter: Reciter) {
        self.storage = storage
        self.quran = quran
        self.timingProvider = timings
        self.positions = positions
        self.reciter = reciter
    }

    /// Starts `surah` from `ayah`, or from its saved position when no ayah is given.
    func play(surah: Surah, reciter: Reciter, fromAyah ayah: Int? = nil) {
        let key = DownloadKey(reciterID: reciter.id, surah: surah.id)
        let local = storage.localURL(for: key)
        let isLocal = FileManager.default.fileExists(atPath: local.path)
        guard let url = isLocal ? local : reciter.remoteURL(forSurah: surah.id) else { return }

        savePosition(force: true)
        startTask?.cancel()
        self.surah = surah
        self.reciter = reciter
        isLocalFile = isLocal
        errorMessage = nil
        currentTime = 0
        duration = 0
        currentAyah = nil
        lastSavedTime = 0
        loadTimings(surah: surah.id, reciter: reciter)

        let item = AVPlayerItem(url: url)
        item.audioTimePitchAlgorithm = .timeDomain
        observeEnd(of: item)
        player.replaceCurrentItem(with: item)

        let resumeAt = ayah == nil ? (try? positions.position(reciterID: reciter.id, surah: surah.id))?.resumeTime : nil
        guard ayah != nil || resumeAt != nil else {
            startPlayback()
            return
        }
        startTask = Task { [weak self] in
            var target = resumeAt
            if let ayah, let timings = await self?.timingTask?.value {
                target = timings.start(of: ayah)
            }
            while item.status == .unknown, !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
            }
            guard let self, !Task.isCancelled, player.currentItem === item else { return }
            if let target {
                seek(to: target)
            }
            startPlayback()
        }
    }

    /// Jumps to `ayah` in the loaded surah, or starts the surah there.
    func play(ayah: Int, in surah: Surah, reciter: Reciter) {
        if self.surah?.id == surah.id, self.reciter == reciter, let start = timings?.start(of: ayah) {
            seek(to: start)
            resume()
        } else {
            play(surah: surah, reciter: reciter, fromAyah: ayah)
        }
    }

    func togglePlayPause() {
        isPlaying ? pause() : resume()
    }

    func resume() {
        guard player.currentItem != nil else { return }
        startPlayback()
    }

    func pause() {
        player.pause()
        refresh()
        savePosition(force: true)
    }

    func next() { step(by: 1) }

    func previous() {
        currentTime > 5 ? seek(to: 0) : step(by: -1)
    }

    func seek(to seconds: Double) {
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        currentTime = seconds
        currentAyah = timings?.ayah(at: seconds)
        publishNowPlaying()
    }

    func setRate(_ newRate: Double) {
        rate = newRate
        player.defaultRate = Float(newRate)
        if player.rate > 0 {
            player.rate = Float(newRate)
        }
        publishNowPlaying()
    }

    /// Switches reciter, restarting the current surah if something is loaded.
    func setReciter(_ newReciter: Reciter) {
        guard newReciter != reciter else { return }
        guard let surah else {
            reciter = newReciter
            return
        }
        let wasPlaying = isPlaying
        play(surah: surah, reciter: newReciter)
        if !wasPlaying { pause() }
    }

    private func startPlayback() {
        player.defaultRate = Float(rate)
        player.play()
        refresh()
    }

    private func loadTimings(surah: Int, reciter: Reciter) {
        timings = nil
        timingTask?.cancel()
        timingTask = Task { [weak self, timingProvider] in
            let loaded = try? await timingProvider.timings(reciter: reciter, surah: surah)
            guard let self, !Task.isCancelled, self.surah?.id == surah, self.reciter == reciter else { return nil }
            timings = loaded
            refresh()
            return loaded
        }
    }

    private func step(by offset: Int) {
        guard let surah, let target = try? quran.surah(id: surah.id + offset) else { return }
        play(surah: target, reciter: reciter)
    }

    private func observeEnd(of item: AVPlayerItem) {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification, object: item, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.surahFinished() }
        }
    }

    func refresh() {
        isPlaying = player.timeControlStatus != .paused
        isBuffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
        currentTime = player.currentTime().seconds.finiteOrZero
        duration = (player.currentItem?.duration.seconds).map(\.finiteOrZero) ?? 0
        let ayah = timings?.ayah(at: currentTime)
        if ayah != currentAyah {
            currentAyah = ayah
        }
        if player.currentItem?.status == .failed {
            errorMessage = player.currentItem?.error?.localizedDescription ?? "Playback failed."
            isPlaying = false
        }
        if isPlaying {
            savePosition()
        }
        publishNowPlaying()
    }
}

private extension Double {
    var finiteOrZero: Double { isFinite ? self : 0 }
}
