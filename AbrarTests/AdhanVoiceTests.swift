import AVFoundation
import Foundation
import Testing
@testable import Abrar

struct AdhanVoiceTests {
    @Test func builtInVoicesAreBundled() {
        #expect(Set(AdhanVoice.builtIn.map(\.id)).count == AdhanVoice.builtIn.count)
        #expect(AdhanVoice.builtIn.first?.id == AdhanVoice.defaultID)
        for voice in AdhanVoice.builtIn {
            #expect(voice.fullAdhan != nil, "\(voice.id) is missing its full adhan")
            let clip = (voice.notificationSound as NSString).deletingPathExtension
            #expect(Bundle.main.url(forResource: clip, withExtension: "caf") != nil, "\(voice.id) is missing its clip")
        }
    }

    @Test func removedVoiceFallsBackToDefault() {
        var settings = AppSettings()
        settings.adhanVoiceID = "gone"
        #expect(settings.adhanVoice.id == AdhanVoice.defaultID)
    }

    @Test func customVoiceIsSelectable() {
        var settings = AppSettings()
        let custom = CustomAdhan(name: "Home mosque", fileExtension: "mp3")
        settings.customAdhans = [custom]
        settings.adhanVoiceID = custom.id.uuidString
        #expect(settings.adhanVoice.name == "Home mosque")
        #expect(settings.adhanVoice.isCustom)
        #expect(settings.adhanVoice.notificationSound == "Abrar-\(custom.id.uuidString).caf")
        #expect(settings.adhanVoices.count == AdhanVoice.builtIn.count + 1)
    }

    @Test func roundTrip() throws {
        let repository = GRDBSettingsRepository(database: try UserDatabase.inMemory())
        var settings = AppSettings()
        let custom = CustomAdhan(name: "Home mosque", fileExtension: "m4a")
        settings.customAdhans = [custom]
        settings.adhanVoiceID = custom.id.uuidString
        try repository.save(settings)
        #expect(try repository.load() == settings)
    }
}

struct AdhanImporterTests {
    private let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)

    private func tone(seconds: Double) throws -> URL {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let url = root.appendingPathComponent("My Adhan.wav")
        let format = try #require(AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1))
        let frames = AVAudioFrameCount(seconds * format.sampleRate)
        let buffer = try #require(AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames))
        buffer.frameLength = frames
        let samples = try #require(buffer.floatChannelData)[0]
        for i in 0..<Int(frames) {
            samples[i] = sin(Float(i) * 2 * .pi * 440 / 44100) * 0.5
        }
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
        return url
    }

    @Test func importsRecordingAndCutsClip() throws {
        let source = try tone(seconds: 40)
        let folder = root.appendingPathComponent("Adhans")
        let sounds = root.appendingPathComponent("Sounds")
        defer { try? FileManager.default.removeItem(at: root) }

        let adhan = try AdhanImporter.importRecording(at: source, into: folder, sounds: sounds)
        #expect(adhan.name == "My Adhan")
        #expect(adhan.fileExtension == "wav")
        #expect(FileManager.default.fileExists(atPath: folder.appendingPathComponent(adhan.fileName).path))

        let clip = try AVAudioFile(forReading: sounds.appendingPathComponent(adhan.soundFileName))
        let duration = Double(clip.length) / clip.fileFormat.sampleRate
        #expect(abs(duration - AdhanImporter.clipSeconds) < 0.1)

        AdhanImporter.remove(adhan, from: folder, sounds: sounds)
        #expect(!FileManager.default.fileExists(atPath: folder.appendingPathComponent(adhan.fileName).path))
        #expect(!FileManager.default.fileExists(atPath: sounds.appendingPathComponent(adhan.soundFileName).path))
    }

    @Test func shortRecordingKeepsItsLength() throws {
        let source = try tone(seconds: 5)
        defer { try? FileManager.default.removeItem(at: root) }
        let destination = root.appendingPathComponent("clip.caf")
        try AdhanImporter.makeClip(from: source, to: destination)
        let clip = try AVAudioFile(forReading: destination)
        #expect(abs(Double(clip.length) / clip.fileFormat.sampleRate - 5) < 0.1)
    }

    @Test func rejectsUnreadableFile() throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let source = root.appendingPathComponent("notes.mp3")
        try Data("not audio".utf8).write(to: source)
        let folder = root.appendingPathComponent("Adhans")
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(throws: AdhanImportError.self) {
            try AdhanImporter.importRecording(at: source, into: folder, sounds: root.appendingPathComponent("Sounds"))
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).isEmpty)
    }
}
