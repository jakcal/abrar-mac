import Foundation
import Observation

enum DownloadState: Equatable, Sendable {
    case notDownloaded
    case downloading(Double)
    case downloaded(Int64)
    case failed(String)
}

@MainActor
@Observable
final class DownloadManager {
    private(set) var states: [DownloadKey: DownloadState] = [:]

    @ObservationIgnored let storage: AudioStorage
    @ObservationIgnored private let timings: AyahTimingProviding
    @ObservationIgnored private var session: URLSession?
    @ObservationIgnored private var tasks: [DownloadKey: URLSessionDownloadTask] = [:]

    init(storage: AudioStorage, timings: AyahTimingProviding) {
        self.storage = storage
        self.timings = timings
    }

    func start(sessionIdentifier: String) {
        let delegate = DownloadSessionDelegate(storage: storage) { [weak self] event in
            Task { @MainActor in self?.handle(event) }
        }
        let configuration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        self.session = session
        Task {
            // Reattach to downloads that kept running while the app was closed.
            for task in await session.allTasks {
                guard let download = task as? URLSessionDownloadTask,
                      let key = DownloadKey(taskDescription: download.taskDescription) else { continue }
                tasks[key] = download
                states[key] = .downloading(download.progress.fractionCompleted)
            }
        }
    }

    func state(for key: DownloadKey) -> DownloadState {
        if let state = states[key] { return state }
        return storage.fileSize(for: key).map(DownloadState.downloaded) ?? .notDownloaded
    }

    func download(_ key: DownloadKey, from url: URL) {
        guard let session, tasks[key] == nil else { return }
        // Cache ayah timings too so highlighting works offline.
        Task { [timings] in
            _ = try? await timings.timings(reciter: Reciter.with(id: key.reciterID), surah: key.surah)
        }
        let task = session.downloadTask(with: url)
        task.taskDescription = key.taskDescription
        tasks[key] = task
        states[key] = .downloading(0)
        task.resume()
    }

    func cancel(_ key: DownloadKey) {
        tasks.removeValue(forKey: key)?.cancel()
        states[key] = nil
    }

    func delete(_ key: DownloadKey) {
        try? storage.delete(key)
        states[key] = .notDownloaded
    }

    func downloadedSizes(reciterID: String) -> [Int: Int64] {
        _ = states  // registers observation so views refresh after downloads and deletes
        return storage.downloadedSizes(reciterID: reciterID)
    }

    private func handle(_ event: DownloadEvent) {
        switch event {
        case let .progress(key, fraction):
            states[key] = .downloading(fraction)
        case let .finished(key, size):
            tasks[key] = nil
            states[key] = .downloaded(size)
        case let .failed(key, message):
            tasks[key] = nil
            states[key] = .failed(message)
        }
    }
}
