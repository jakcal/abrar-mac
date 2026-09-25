import Foundation

enum DownloadEvent: Sendable {
    case progress(DownloadKey, Double)
    case finished(DownloadKey, Int64)
    case failed(DownloadKey, String)
}

/// Background URLSession delegate. Moves finished files into place before the temporary file is deleted.
final class DownloadSessionDelegate: NSObject, URLSessionDownloadDelegate, Sendable {
    private let storage: AudioStorage
    private let onEvent: @Sendable (DownloadEvent) -> Void

    init(storage: AudioStorage, onEvent: @escaping @Sendable (DownloadEvent) -> Void) {
        self.storage = storage
        self.onEvent = onEvent
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let key = DownloadKey(taskDescription: downloadTask.taskDescription),
              totalBytesExpectedToWrite > 0 else { return }
        onEvent(.progress(key, Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let key = DownloadKey(taskDescription: downloadTask.taskDescription) else { return }
        if let response = downloadTask.response as? HTTPURLResponse, !(200..<300).contains(response.statusCode) {
            onEvent(.failed(key, "Server returned \(response.statusCode)"))
            return
        }
        do {
            onEvent(.finished(key, try storage.store(location, for: key)))
        } catch {
            onEvent(.failed(key, error.localizedDescription))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error, let key = DownloadKey(taskDescription: task.taskDescription) else { return }
        if (error as? URLError)?.code == .cancelled { return }
        onEvent(.failed(key, error.localizedDescription))
    }
}
