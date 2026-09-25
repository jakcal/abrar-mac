import CoreLocation
import Foundation

@MainActor
protocol LocationProviding: AnyObject {
    func currentPlace() async throws -> Place
}

enum LocationError: LocalizedError {
    case denied
    case busy

    var errorDescription: String? {
        switch self {
        case .denied: "Location access is off. Allow it in System Settings or pick a city."
        case .busy: "A location request is already running."
        }
    }
}

@MainActor
final class CoreLocationService: NSObject, LocationProviding, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var pending: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func currentPlace() async throws -> Place {
        let location = try await requestLocation()
        return await place(for: location)
    }

    private func requestLocation() async throws -> CLLocation {
        switch manager.authorizationStatus {
        case .denied, .restricted: throw LocationError.denied
        default: break
        }
        guard pending == nil else { throw LocationError.busy }
        return try await withCheckedThrowingContinuation { continuation in
            pending = continuation
            if manager.authorizationStatus == .notDetermined {
                manager.requestWhenInUseAuthorization()
            } else {
                manager.requestLocation()
            }
        }
    }

    private func place(for location: CLLocation) async -> Place {
        let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first
        return Place(
            name: placemark?.locality ?? placemark?.name ?? "Current Location",
            country: placemark?.country ?? "",
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            timeZoneID: (placemark?.timeZone ?? .current).identifier
        )
    }

    private func finish(_ result: Result<CLLocation, Error>) {
        pending?.resume(with: result)
        pending = nil
    }

    private func authorizationChanged(_ status: CLAuthorizationStatus) {
        guard pending != nil else { return }
        switch status {
        case .denied, .restricted: finish(.failure(LocationError.denied))
        case .notDetermined: break
        default: manager.requestLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in self.authorizationChanged(status) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in self.finish(.success(location)) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.finish(.failure(error)) }
    }
}
