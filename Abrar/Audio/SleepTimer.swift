import Foundation

enum SleepTimer: Equatable, Sendable {
    case at(Date)
    case endOfSurah

    static let presetMinutes = [5, 10, 15, 30, 45, 60]
}

extension AudioPlayerService {
    static let playbackRates: [Double] = [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]

    func setSleepTimer(minutes: Int) {
        let deadline = Date().addingTimeInterval(TimeInterval(minutes * 60))
        sleepTask?.cancel()
        sleepTimer = .at(deadline)
        sleepTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(deadline.timeIntervalSinceNow))
            guard let self, !Task.isCancelled else { return }
            sleepTimer = nil
            pause()
        }
    }

    func setSleepTimerToEndOfSurah() {
        sleepTask?.cancel()
        sleepTimer = .endOfSurah
    }

    func cancelSleepTimer() {
        sleepTask?.cancel()
        sleepTask = nil
        sleepTimer = nil
    }
}
