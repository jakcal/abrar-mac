import AVFoundation

@MainActor
protocol AdhanPlaying: AnyObject {
    var isPlaying: Bool { get }
    func play()
    func stop()
}

@MainActor
final class AdhanAudioPlayer: AdhanPlaying {
    private var player: AVAudioPlayer?

    var isPlaying: Bool { player?.isPlaying ?? false }

    func play() {
        guard let url = Bundle.main.url(forResource: "adhan_full", withExtension: "m4a") else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
