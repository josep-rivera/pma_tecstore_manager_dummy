import Foundation
import MapKit
import CoreLocation

// ─────────────────────────────────────────────
// MARK: - ClientFormValidation
// ─────────────────────────────────────────────

struct ClientFormValidation {
    let dniError: String?
    let firstNamesError: String?
    let lastNamesError: String?
    let emailError: String?

    var isValid: Bool {
        dniError == nil && firstNamesError == nil && lastNamesError == nil && emailError == nil
    }

    static let valid = ClientFormValidation(dniError: nil, firstNamesError: nil,
                                            lastNamesError: nil, emailError: nil)
}

struct ClientFormValues {
    let dni: String
    let firstNames: String
    let lastNames: String
    let phone: String
    let email: String
    let address: String
    let isActive: Bool
}

// ─────────────────────────────────────────────
// MARK: - FormularioClienteViewModel
// ─────────────────────────────────────────────

final class FormularioClienteViewModel {

    // MARK: Outputs

    var onLoading: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    var onSuccess: (() -> Void)?
    var onValidationErrors: ((ClientFormValidation) -> Void)?
    var onCoordinateUpdate: ((CLLocationCoordinate2D?) -> Void)?
    var onSuggestedAddress: ((String?) -> Void)?
    var onSaveEnabled: ((Bool) -> Void)?
    var onFormValuesChanged: ((ClientFormValues) -> Void)?
    var onEstadoChanged: ((Bool) -> Void)?

    // MARK: State

    private(set) var client: FBCliente?
    private var isEditMode: Bool { client != nil }

    private var dni: String = ""
    private var firstNames: String = ""
    private var lastNames: String = ""
    private var phone: String = ""
    private var email: String = ""
    private var address: String = ""
    private var isActive: Bool = true
    private var coordinate: CLLocationCoordinate2D?

    private var hasAttemptedSubmit = false
    private var geocodeTimer: Timer?

    // MARK: Configuration

    func configure(with client: FBCliente?) {
        self.client = client

        if let client {
            dni = client.dniValue
            firstNames = client.firstNames
            lastNames = client.lastNames
            phone = client.phoneNumber ?? ""
            email = client.emailValue ?? ""
            address = client.addressValue ?? ""
            isActive = client.isActive

            if client.hasValidCoordinates {
                coordinate = CLLocationCoordinate2D(latitude: client.latitude,
                                                    longitude: client.longitude)
                onCoordinateUpdate?(coordinate)
            } else {
                onCoordinateUpdate?(nil)
            }

            onEstadoChanged?(isActive)
            onSaveEnabled?(true)
        } else {
            onSaveEnabled?(false)
            onCoordinateUpdate?(nil)
        }
        emitFormValues()
    }

    private func emitFormValues() {
        onFormValuesChanged?(
            ClientFormValues(dni: dni, firstNames: firstNames, lastNames: lastNames,
                             phone: phone, email: email, address: address, isActive: isActive)
        )
    }

    // MARK: Inputs

    func updateDNI(_ value: String) {
        dni = value.trimmed
        emitFormValues()
        if hasAttemptedSubmit { validate() }
    }

    func updateFirstNames(_ value: String) {
        firstNames = value.trimmed
        emitFormValues()
        if hasAttemptedSubmit { validate() }
    }

    func updateLastNames(_ value: String) {
        lastNames = value.trimmed
        emitFormValues()
        if hasAttemptedSubmit { validate() }
    }

    func updatePhone(_ value: String) {
        phone = value
        emitFormValues()
    }

    func updateEmail(_ value: String) {
        email = value.trimmed
        emitFormValues()
        if hasAttemptedSubmit { validate() }
    }

    func updateAddress(_ value: String) {
        address = value.trimmed
        emitFormValues()
        scheduleGeocode()
    }

    func updateCoordinate(_ newCoordinate: CLLocationCoordinate2D) {
        coordinate = newCoordinate
        onCoordinateUpdate?(newCoordinate)

        ClienteLocationService.shared.reverseGeocode(coordinate: newCoordinate) { [weak self] address in
            guard let address else { return }
            self?.address = address
            self?.emitFormValues()
            self?.onSuggestedAddress?(address)
        }
    }

    func updateEstado(_ isOn: Bool) {
        isActive = isOn
        onEstadoChanged?(isActive)
        emitFormValues()
    }

    func sanitizeDNILength(_ value: String) -> String {
        value.count > 8 ? String(value.prefix(8)) : value
    }

    // MARK: Save

    func save() {
        hasAttemptedSubmit = true
        let validation = performValidation()
        onValidationErrors?(validation)
        guard validation.isValid else { return }

        let status = isActive ? "Activo" : "Inactivo"
        let phoneValue = phone.isEmpty ? nil : phone
        let emailValue = email.isEmpty ? nil : email
        let addressValue = address.isEmpty ? nil : address

        onLoading?(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                let clientID: String
                if let client = self.client {
                    try await ClienteService.shared.update(
                        client,
                        dni: self.dni,
                        nombres: self.firstNames,
                        apellidos: self.lastNames,
                        telefono: phoneValue,
                        correo: emailValue,
                        direccion: addressValue,
                        estado: status
                    )
                    clientID = client.id ?? ""
                } else {
                    clientID = try await ClienteService.shared.create(
                        dni: self.dni,
                        nombres: self.firstNames,
                        apellidos: self.lastNames,
                        telefono: phoneValue,
                        correo: emailValue,
                        direccion: addressValue
                    )
                }

                if let coordinate = self.coordinate,
                   coordinate.latitude != 0 || coordinate.longitude != 0 {
                    try await UbicacionService.shared.saveOrUpdate(
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        reference: addressValue,
                        clienteID: clientID
                    )
                }

                await MainActor.run {
                    self.onLoading?(false)
                    self.onSuccess?()
                }
            } catch let error as ServiceError {
                await MainActor.run {
                    self.onLoading?(false)
                    self.onError?(error.errorDescription ?? "")
                }
            } catch {
                await MainActor.run {
                    self.onLoading?(false)
                    self.onError?(error.localizedDescription)
                }
            }
        }
    }

    // MARK: Cleanup

    func cancelPendingGeocode() {
        geocodeTimer?.invalidate()
        ClienteLocationService.shared.cancel()
    }

    // MARK: Private

    private func scheduleGeocode() {
        geocodeTimer?.invalidate()
        let trimmed = address.trimmed
        guard trimmed.count > 6 else { return }

        geocodeTimer = Timer.scheduledTimer(withTimeInterval: 0.9, repeats: false) { [weak self] _ in
            self?.geocodeAddress(trimmed)
        }
    }

    private func geocodeAddress(_ address: String) {
        ClienteLocationService.shared.geocode(address: address) { [weak self] coordinate in
            guard let coordinate else { return }
            self?.coordinate = coordinate
            self?.onCoordinateUpdate?(coordinate)
        }
    }

    private func validate() {
        let validation = performValidation()
        onValidationErrors?(validation)
        onSaveEnabled?(validation.isValid)
    }

    private func performValidation() -> ClientFormValidation {
        let dniError: String?
        if dni.isEmpty {
            dniError = "DNI is required."
        } else if !dni.isValidDNI {
            dniError = "DNI must be exactly 8 digits."
        } else {
            dniError = nil
        }

        let firstNamesError: String? = firstNames.isEmpty ? "First names are required." : nil
        let lastNamesError: String? = lastNames.isEmpty ? "Last names are required." : nil

        let emailError: String?
        if email.isNotBlank && !email.isValidEmail {
            emailError = "Invalid email format."
        } else {
            emailError = nil
        }

        return ClientFormValidation(dniError: dniError,
                                    firstNamesError: firstNamesError,
                                    lastNamesError: lastNamesError,
                                    emailError: emailError)
    }
}
