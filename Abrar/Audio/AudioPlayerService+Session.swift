import AppKit
import AVFoundation

/// Launch wiring, Now Playing and per-surah listening positions.
extension AudioPlayerService {
    /// Hooks up the periodic observer and media keys. Call once at launch.
    func start() {
        nowPlaying = NowPlayingController(handlers: .init(
            play: { [weak self] in self?.resume() },
            pause: { [weak self] in self?.pause() },
            toggle: { [weak self] in self?.togglePlayPause() },
            next: { [weak self] in self?.next() },
            previous: { [weak self] in self?.previous() },
            seek: { [weak self] in self?.seek(to: $0) }
        ))
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.savePosition(force: true) }
        })
    }

    func resumeTime(for surah: Surah, reciter: Reciter) -> Double? {
        (try? positions.position(reciterID: reciter.id, surah: surah.id))?.resumeTime
    }

    func surahFinished() {
        if let surah {
            try? positions.clear(reciterID: reciter.id, surah: surah.id)
        }
        lastSavedTime = 0
        if sleepTimer == .endOfSurah {
            cancelSleepTimer()
            refresh()
            return
        }
        seek(to: 0)
        next()
    }

    func savePosition(force: Bool = false) {
        guard let surah, currentTime > 0, force || abs(currentTime - lastSavedTime) >= 5 else { return }
        lastSavedTime = currentTime
        try? positions.save(ListeningPosition(reciterID: reciter.id, surah: surah.id, position: currentTime, duration: duration))
    }

    func publishNowPlaying() {
        guard let surah else {
            nowPlaying?.clear()
            return
        }
        nowPlaying?.update(
            title: "\(surah.id). \(surah.nameTransliterated) · \(surah.nameArabic)",
            artist: reciter.displayName,
            duration: duration,
            elapsed: currentTime,
            rate: isPlaying ? rate : 0
        )
    }
}
