import Foundation
import FirebaseFirestore
import CoreLocation

// ─────────────────────────────────────────────
// MARK: - UbicacionService
// ─────────────────────────────────────────────

final class UbicacionService {

    // MARK: Singleton
    static let shared = UbicacionService()
    private init() {}

    private let db = Firestore.firestore()

    // ─────────────────────────────────────────
    // MARK: - Fetch
    // ─────────────────────────────────────────

    /// Returns the embedded `ubicacion` map from the client's Firestore document.
    /// This is derived from the parent `FBCliente`; no separate collection exists.
    func fetchUbicacion(clienteID: String) async throws -> FBUbicacion? {
        let cliente = try await FirestoreService.fetch(
            Collections.clientes, id: clienteID, as: FBCliente.self
        )
        return cliente?.ubicacion
    }

    // ─────────────────────────────────────────
    // MARK: - Save / Update  (upsert)
    // ─────────────────────────────────────────

    /// Persist (or replace) the `ubicacion` nested map on the parent `/clientes/{id}` document.
    ///
    /// - Throws: `ServiceError.notFound` if the client has no document ID.
    func saveOrUpdate(
        latitude:   Double,
        longitude:  Double,
        reference:  String?,
        clienteID:  String
    ) async throws {
        let ref = reference?.trimmed.isNotBlank == true ? reference?.trimmed : nil
        let ubicacionMap: [String: Any] = [
            "latitud":             latitude,
            "longitud":            longitude,
            "direccionReferencia": ref as Any? ?? NSNull(),
            "fechaRegistro":       Timestamp(date: Date())
        ]
        try await FirestoreService.update(
            Collections.clientes,
            id: clienteID,
            ["ubicacion": ubicacionMap]
        )
    }

    // ─────────────────────────────────────────
    // MARK: - Device GPS
    // ─────────────────────────────────────────

    /// Returns the device's current CLLocationCoordinate2D via a one-shot
    /// CLLocationManager callback. The completion is called on the main thread.
    /// If location permission is denied, the completion is called with nil.
    func requestCurrentDeviceLocation(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        DeviceLocationHelper.shared.requestOnce(completion: completion)
    }
}

// ─────────────────────────────────────────────
// MARK: - DeviceLocationHelper  (internal, one-shot GPS)
// ─────────────────────────────────────────────

/// Wraps CLLocationManager for a single one-shot coordinate request.
/// Only used by UbicacionService — not exposed publicly.
private final class DeviceLocationHelper: NSObject, CLLocationManagerDelegate {

    static let shared = DeviceLocationHelper()
    private override init() { super.init() }

    private let manager  = CLLocationManager()
    private var callback: ((CLLocationCoordinate2D?) -> Void)?

    func requestOnce(completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        callback = completion
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            deliver(nil)
        }
    }

    // MARK: CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        deliver(locations.first?.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("DeviceLocation error: \(error.localizedDescription)")
        deliver(nil)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            deliver(nil)
        default:
            break
        }
    }

    private func deliver(_ coordinate: CLLocationCoordinate2D?) {
        guard let cb = callback else { return }
        callback = nil
        DispatchQueue.main.async { cb(coordinate) }
    }
}
