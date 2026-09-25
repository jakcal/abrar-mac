import MediaPlayer

/// Publishes playback info to Control Center and routes media keys back to the player.
@MainActor
final class NowPlayingController {
    struct Handlers {
        var play: @MainActor () -> Void
        var pause: @MainActor () -> Void
        var toggle: @MainActor () -> Void
        var next: @MainActor () -> Void
        var previous: @MainActor () -> Void
        var seek: @MainActor (Double) -> Void
    }

    init(handlers: Handlers) {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { _ in
            MainActor.assumeIsolated { handlers.play() }
            return .success
        }
        center.pauseCommand.addTarget { _ in
            MainActor.assumeIsolated { handlers.pause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { _ in
            MainActor.assumeIsolated { handlers.toggle() }
            return .success
        }
        center.nextTrackCommand.addTarget { _ in
            MainActor.assumeIsolated { handlers.next() }
            return .success
        }
        center.previousTrackCommand.addTarget { _ in
            MainActor.assumeIsolated { handlers.previous() }
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let position = event.positionTime
            MainActor.assumeIsolated { handlers.seek(position) }
            return .success
        }
    }

    func update(title: String, artist: String, duration: Double, elapsed: Double, rate: Double) {
        let center = MPNowPlayingInfoCenter.default()
        center.nowPlayingInfo = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyAlbumTitle: "Al-Qur'an",
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
            MPNowPlayingInfoPropertyPlaybackRate: rate,
        ]
        center.playbackState = rate > 0 ? .playing : .paused
    }

    func clear() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPNowPlayingInfoCenter.default().playbackState = .stopped
    }
}
