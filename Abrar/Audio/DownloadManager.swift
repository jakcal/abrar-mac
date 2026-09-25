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
    /// Reciters with a "download all" run in progress.
    private var bulkReciters: Set<String> = []
    @ObservationIgnored private var timingPrefetch: [String: Task<Void, Never>] = [:]

    init(storage: AudioStorage, timings: AyahTimingProviding) {
        self.storage = storage
        self.timings = timings
    }

    func start(sessionIdentifier: String) {
        let delegate = DownloadSessionDelegate(storage: storage) { [weak self] event in
            Task { @MainActor in self?.handle(event) }
        }
        let configuration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        // Keeps "download all" from opening 114 connections at once.
        configuration.httpMaximumConnectionsPerHost = 4
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
            let reattached = Dictionary(grouping: tasks.keys, by: \.reciterID)
            bulkReciters = Set(reattached.filter { $0.value.count > 1 }.keys)
        }
    }

    func state(for key: DownloadKey) -> DownloadState {
        if let state = states[key] { return state }
        return storage.fileSize(for: key).map(DownloadState.downloaded) ?? .notDownloaded
    }

    func download(_ key: DownloadKey, from url: URL) {
        guard tasks[key] == nil else { return }
        // Cache ayah timings too so highlighting works offline.
        Task { [timings] in
            _ = try? await timings.timings(reciter: Reciter.with(id: key.reciterID), surah: key.surah)
        }
        enqueue(key, from: url)
    }

    private func enqueue(_ key: DownloadKey, from url: URL) {
        guard let session, tasks[key] == nil else { return }
        let task = session.downloadTask(with: url)
        task.taskDescription = key.taskDescription
        tasks[key] = task
        states[key] = .downloading(0)
        task.resume()
    }

    func cancel(_ key: DownloadKey) {
        tasks.removeValue(forKey: key)?.cancel()
        states[key] = nil
        endBulkRunIfIdle(key.reciterID)
    }

    func delete(_ key: DownloadKey) {
        try? storage.delete(key)
        states[key] = .notDownloaded
    }

    func downloadedSizes(reciterID: String) -> [Int: Int64] {
        _ = states  // registers observation so views refresh after downloads and deletes
        return storage.downloadedSizes(reciterID: reciterID)
    }

    /// Queues every surah of `reciter` that isn't saved or already downloading.
    func downloadAll(reciter: Reciter) {
        let saved = storage.downloadedSizes(reciterID: reciter.id)
        let missing = (1...BulkDownloadProgress.surahCount).filter {
            saved[$0] == nil && tasks[DownloadKey(reciterID: reciter.id, surah: $0)] == nil
        }
        guard !missing.isEmpty else { return }
        bulkReciters.insert(reciter.id)
        for surah in missing {
            guard let url = reciter.remoteURL(forSurah: surah) else { continue }
            enqueue(DownloadKey(reciterID: reciter.id, surah: surah), from: url)
        }
        // One timing request at a time rather than 114 in parallel.
        timingPrefetch[reciter.id]?.cancel()
        timingPrefetch[reciter.id] = Task { [timings] in
            for surah in missing where !Task.isCancelled {
                _ = try? await timings.timings(reciter: reciter, surah: surah)
            }
        }
    }

    func cancelAll(reciterID: String) {
        for key in tasks.keys where key.reciterID == reciterID {
            tasks.removeValue(forKey: key)?.cancel()
            states[key] = nil
        }
        timingPrefetch.removeValue(forKey: reciterID)?.cancel()
        bulkReciters.remove(reciterID)
    }

    func deleteAll(reciterID: String) {
        cancelAll(reciterID: reciterID)
        for surah in storage.downloadedSizes(reciterID: reciterID).keys {
            delete(DownloadKey(reciterID: reciterID, surah: surah))
        }
    }

    func bulkProgress(reciterID: String) -> BulkDownloadProgress {
        let reciterStates = states.filter { $0.key.reciterID == reciterID }
        return BulkDownloadProgress(
            sizes: downloadedSizes(reciterID: reciterID),
            states: Dictionary(uniqueKeysWithValues: reciterStates.map { ($0.key.surah, $0.value) }),
            isBulkRun: bulkReciters.contains(reciterID)
        )
    }

    private func endBulkRunIfIdle(_ reciterID: String) {
        guard !tasks.keys.contains(where: { $0.reciterID == reciterID }) else { return }
        bulkReciters.remove(reciterID)
    }

    private func handle(_ event: DownloadEvent) {
        switch event {
        case let .progress(key, fraction):
            // Late progress from a cancelled task shouldn't resurrect it.
            guard tasks[key] != nil else { return }
            states[key] = .downloading(fraction)
        case let .finished(key, size):
            tasks[key] = nil
            states[key] = .downloaded(size)
            endBulkRunIfIdle(key.reciterID)
        case let .failed(key, message):
            tasks[key] = nil
            states[key] = .failed(message)
            endBulkRunIfIdle(key.reciterID)
        }
    }
}
