import AVFoundation

enum AdhanImportError: LocalizedError {
    case unreadable

    var errorDescription: String? {
        "Abrar can't read this recording. Try an MP3, M4A, WAV or AIFF file."
    }
}

/// Copies a user's recording in and cuts the short clip notifications play.
enum AdhanImporter {
    /// Notification sounds longer than 30 seconds fall back to the default tone.
    static let clipSeconds = 28.0
    static let fadeSeconds = 3.0

    static func importRecording(
        at source: URL,
        into folder: URL = AppPaths.customAdhans,
        sounds: URL = AppPaths.notificationSounds
    ) throws -> CustomAdhan {
        let adhan = CustomAdhan(
            name: source.deletingPathExtension().lastPathComponent,
            fileExtension: source.pathExtension.lowercased()
        )
        let files = FileManager.default
        try files.createDirectory(at: folder, withIntermediateDirectories: true)
        try files.createDirectory(at: sounds, withIntermediateDirectories: true)
        let full = folder.appendingPathComponent(adhan.fileName)
        try files.copyItem(at: source, to: full)
        do {
            try makeClip(from: full, to: sounds.appendingPathComponent(adhan.soundFileName))
        } catch {
            try? files.removeItem(at: full)
            throw error
        }
        return adhan
    }

    static func remove(
        _ adhan: CustomAdhan,
        from folder: URL = AppPaths.customAdhans,
        sounds: URL = AppPaths.notificationSounds
    ) {
        try? FileManager.default.removeItem(at: folder.appendingPathComponent(adhan.fileName))
        try? FileManager.default.removeItem(at: sounds.appendingPathComponent(adhan.soundFileName))
    }

    /// The first `clipSeconds`, faded out, as 16-bit PCM in CAF.
    static func makeClip(from source: URL, to destination: URL) throws {
        guard let input = try? AVAudioFile(forReading: source), input.length > 0 else {
            throw AdhanImportError.unreadable
        }
        let format = input.processingFormat
        let frames = AVAudioFrameCount(min(Double(input.length), clipSeconds * format.sampleRate))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else {
            throw AdhanImportError.unreadable
        }
        try input.read(into: buffer, frameCount: frames)
        if let channels = buffer.floatChannelData {
            let length = Int(buffer.frameLength)
            let fadeFrames = min(Int(fadeSeconds * format.sampleRate), length)
            for channel in 0..<Int(format.channelCount) {
                for i in (length - fadeFrames)..<length {
                    channels[channel][i] *= Float(length - i) / Float(fadeFrames)
                }
            }
        }
        let output = try AVAudioFile(
            forWriting: destination,
            settings: [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: format.sampleRate,
                AVNumberOfChannelsKey: format.channelCount,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
            ],
            commonFormat: format.commonFormat,
            interleaved: format.isInterleaved
        )
        try output.write(from: buffer)
    }
}
