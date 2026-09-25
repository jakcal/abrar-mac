import Foundation
import Observation

/// Resolves the device location and stores it as the detected place.
@MainActor
@Observable
final class LocationController {
    private(set) var isLocating = false
    private(set) var errorMessage: String?

    @ObservationIgnored private let provider: LocationProviding
    @ObservationIgnored private let store: SettingsStore

    init(provider: LocationProviding, store: SettingsStore) {
        self.provider = provider
        self.store = store
    }

    func refresh() async {
        guard !isLocating else { return }
        isLocating = true
        defer { isLocating = false }
        do {
            store.settings.detectedPlace = try await provider.currentPlace()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
