import Foundation

struct DownloadKey: Hashable, Sendable {
    let reciterID: String
    let surah: Int

    var taskDescription: String { "\(reciterID)/\(surah)" }

    init(reciterID: String, surah: Int) {
        self.reciterID = reciterID
        self.surah = surah
    }

    init?(taskDescription: String?) {
        let parts = taskDescription?.split(separator: "/") ?? []
        guard parts.count == 2, let surah = Int(parts[1]) else { return nil }
        self.init(reciterID: String(parts[0]), surah: surah)
    }
}

/// Downloaded recitations, laid out as `Audio/<reciter>/<surah>.mp3` in Application Support.
struct AudioStorage: Sendable {
    let root: URL

    func localURL(for key: DownloadKey) -> URL {
        root
            .appendingPathComponent(key.reciterID, isDirectory: true)
            .appendingPathComponent(String(format: "%03d.mp3", key.surah))
    }

    func fileSize(for key: DownloadKey) -> Int64? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: localURL(for: key).path)
        return (attributes?[.size] as? NSNumber)?.int64Value
    }

    func store(_ temporaryFile: URL, for key: DownloadKey) throws -> Int64 {
        let destination = localURL(for: key)
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: temporaryFile, to: destination)
        return fileSize(for: key) ?? 0
    }

    func delete(_ key: DownloadKey) throws {
        let url = localURL(for: key)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    func downloadedSizes(reciterID: String) -> [Int: Int64] {
        var sizes: [Int: Int64] = [:]
        for surah in 1...114 {
            if let size = fileSize(for: DownloadKey(reciterID: reciterID, surah: surah)) {
                sizes[surah] = size
            }
        }
        return sizes
    }
}
