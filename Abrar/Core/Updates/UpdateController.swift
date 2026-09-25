import AppKit
import Observation

@MainActor
@Observable
final class UpdateController {
    enum Status: Equatable {
        case idle, checking, upToDate, failed
    }

    private(set) var available: AppRelease?
    private(set) var status: Status = .idle
    private(set) var lastChecked: Date?

    @ObservationIgnored private let checker: ReleaseChecking
    @ObservationIgnored private let currentVersion: AppVersion?
    @ObservationIgnored private var loop: Task<Void, Never>?

    init(checker: ReleaseChecking, currentVersion: AppVersion? = .current) {
        self.checker = checker
        self.currentVersion = currentVersion
    }

    /// Checks shortly after launch, then once a day.
    func startAutomaticChecks() {
        guard loop == nil else { return }
        loop = Task { [weak self] in
            try? await Task.sleep(for: .seconds(10))
            while !Task.isCancelled {
                await self?.check()
                try? await Task.sleep(for: .seconds(24 * 60 * 60))
            }
        }
    }

    func stopAutomaticChecks() {
        loop?.cancel()
        loop = nil
    }

    func check() async {
        guard status != .checking else { return }
        status = .checking
        do {
            let latest = try await checker.latestRelease()
            lastChecked = Date()
            if let latest, let currentVersion, currentVersion < latest.version {
                available = latest
            } else {
                available = nil
            }
            status = .upToDate
        } catch {
            status = .failed
        }
    }

    func download() {
        guard let release = available else { return }
        NSWorkspace.shared.open(release.downloadURL ?? release.pageURL)
    }

    func openReleaseNotes() {
        guard let release = available else { return }
        NSWorkspace.shared.open(release.pageURL)
    }
}
