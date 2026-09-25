// Usage: swift scripts/trim_audio.swift <input> <output.wav> <seconds> [fadeSeconds]
import AVFoundation

let args = CommandLine.arguments
guard args.count >= 4, let seconds = Double(args[3]) else {
    FileHandle.standardError.write(Data("usage: trim_audio.swift <input> <output.wav> <seconds> [fade]\n".utf8))
    exit(1)
}
let fade = args.count > 4 ? Double(args[4]) ?? 2 : 2

do {
    let input = try AVAudioFile(forReading: URL(fileURLWithPath: args[1]))
    let format = input.processingFormat
    let frames = AVAudioFrameCount(min(Double(input.length), seconds * format.sampleRate))
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
          let channels = buffer.floatChannelData else { exit(1) }
    try input.read(into: buffer, frameCount: frames)

    let fadeFrames = Int(fade * format.sampleRate)
    let length = Int(buffer.frameLength)
    for channel in 0..<Int(format.channelCount) {
        for i in max(0, length - fadeFrames)..<length {
            channels[channel][i] *= Float(length - i) / Float(fadeFrames)
        }
    }

    let output = try AVAudioFile(
        forWriting: URL(fileURLWithPath: args[2]),
        settings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
        ]
    )
    try output.write(from: buffer)
} catch {
    FileHandle.standardError.write(Data("trim failed: \(error)\n".utf8))
    exit(1)
}
