import Foundation
import Observation

@MainActor
@Observable
final class SettingsStore {
    var settings: AppSettings {
        didSet {
            guard settings != oldValue else { return }
            persist()
            onChange?(oldValue, settings)
        }
    }

    private(set) var lastError: String?

    @ObservationIgnored var onChange: (@MainActor (_ old: AppSettings, _ new: AppSettings) -> Void)?
    @ObservationIgnored private let repository: SettingsRepository

    init(repository: SettingsRepository) {
        self.repository = repository
        settings = (try? repository.load()) ?? AppSettings()
    }

    private func persist() {
        do {
            try repository.save(settings)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}
