import AVFoundation

@MainActor
protocol AdhanPlaying: AnyObject {
    var isPlaying: Bool { get }
    func play(_ voice: AdhanVoice)
    func stop()
}

@MainActor
final class AdhanAudioPlayer: AdhanPlaying {
    private var player: AVAudioPlayer?

    var isPlaying: Bool { player?.isPlaying ?? false }

    func play(_ voice: AdhanVoice) {
        guard let url = voice.fullAdhan else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
