import Foundation
import MapKit
import CoreLocation

// ─────────────────────────────────────────────
// MARK: - ClienteLocationService
// ─────────────────────────────────────────────

/// Wraps modern MapKit geocoding APIs for client address/location handling.
final class ClienteLocationService {

    // MARK: Singleton

    static let shared = ClienteLocationService()
    private init() {}

    // MARK: State

    private var activeGeocodeRequest: MKGeocodingRequest?
    private var activeReverseRequest: MKReverseGeocodingRequest?

    // MARK: Public API

    /// Geocodes a human-readable address into coordinates using `MKGeocodingRequest`.
    func geocode(address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        activeGeocodeRequest?.cancel()

        guard let request = MKGeocodingRequest(addressString: address) else {
            completion(nil)
            return
        }
        activeGeocodeRequest = request

        Task { [request] in
            guard let item = try? await request.mapItems.first else {
                await MainActor.run {
                    if self.activeGeocodeRequest === request { self.activeGeocodeRequest = nil }
                    completion(nil)
                }
                return
            }
            await MainActor.run {
                if self.activeGeocodeRequest === request { self.activeGeocodeRequest = nil }
                completion(item.location.coordinate)
            }
        }
    }

    /// Reverse geocodes a coordinate into a human-readable address string.
    func reverseGeocode(coordinate: CLLocationCoordinate2D,
                        completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        activeReverseRequest?.cancel()

        guard let request = MKReverseGeocodingRequest(location: location) else {
            completion(nil)
            return
        }
        activeReverseRequest = request

        Task { [request] in
            guard let item = try? await request.mapItems.first else {
                await MainActor.run {
                    if self.activeReverseRequest === request { self.activeReverseRequest = nil }
                    completion(nil)
                }
                return
            }
            let address = item.addressRepresentations?
                .fullAddress(includingRegion: false, singleLine: true) ?? ""
            await MainActor.run {
                if self.activeReverseRequest === request { self.activeReverseRequest = nil }
                completion(address.isEmpty ? nil : address)
            }
        }
    }

    /// Cancels any in-flight geocoding request.
    func cancel() {
        activeGeocodeRequest?.cancel()
        activeGeocodeRequest = nil
        activeReverseRequest?.cancel()
        activeReverseRequest = nil
    }
}
