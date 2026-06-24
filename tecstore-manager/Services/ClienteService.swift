import Foundation
import FirebaseFirestore

// ─────────────────────────────────────────────
// MARK: - ClienteService
// ─────────────────────────────────────────────

final class ClienteService {

    // MARK: Singleton
    static let shared = ClienteService()
    private init() {}

    private let db = Firestore.firestore()

    // ─────────────────────────────────────────
    // MARK: - Fetch
    // ─────────────────────────────────────────

    /// All clients sorted by apellidos. Client-side filter avoids composite index requirement.
    func fetchAll(onlyActive: Bool = false) async throws -> [FBCliente] {
        let snap = try await db.collection(Collections.clientes).getDocuments()
        var all = try snap.documents.map { try $0.data(as: FBCliente.self) }
        if onlyActive { all = all.filter { $0.isActive } }
        return all.sorted { $0.apellidos.localizedCompare($1.apellidos) == .orderedAscending }
    }

    /// Single client by document ID, or nil if not found.
    func fetch(byID id: String) async throws -> FBCliente? {
        return try await FirestoreService.fetch(Collections.clientes, id: id, as: FBCliente.self)
    }

    /// Single client by DNI, or nil if not found.
    func fetch(byDNI dni: String) async throws -> FBCliente? {
        let snap = try await db.collection(Collections.clientes)
            .whereField("dni", isEqualTo: dni.trimmed)
            .limit(to: 1)
            .getDocuments()
        return try snap.documents.first.map { try $0.data(as: FBCliente.self) }
    }

    // ─────────────────────────────────────────
    // MARK: - Validation
    // ─────────────────────────────────────────

    /// True when no other client uses this 8-digit DNI.
    func isDNIUnique(_ dni: String, excludingID: String? = nil) async throws -> Bool {
        let snap = try await db.collection(Collections.clientes)
            .whereField("dni", isEqualTo: dni.trimmed)
            .limit(to: 1)
            .getDocuments()
        guard let doc = snap.documents.first else { return true }
        return doc.documentID == excludingID
    }

    // ─────────────────────────────────────────
    // MARK: - Create
    // ─────────────────────────────────────────

    /// Insert a new client in Firestore.
    ///
    /// - Throws: `ServiceError.duplicateDNI` if the DNI is already taken.
    /// - Returns: The document ID of the newly created client.
    @discardableResult
    func create(
        dni:       String,
        nombres:   String,
        apellidos: String,
        telefono:  String? = nil,
        correo:    String? = nil,
        direccion: String? = nil
    ) async throws -> String {
        guard try await isDNIUnique(dni.trimmed) else {
            throw ServiceError.duplicateDNI
        }

        let cliente = FBCliente(
            id:            nil,
            dni:           dni.trimmed,
            nombres:       nombres.trimmed,
            apellidos:     apellidos.trimmed,
            telefono:      nonEmpty(telefono),
            correo:        nonEmpty(correo),
            direccion:     nonEmpty(direccion),
            estado:        "Activo",
            fechaRegistro: Date(),
            ubicacion:     nil
        )
        return try await FirestoreService.add(Collections.clientes, cliente)
    }

    // ─────────────────────────────────────────
    // MARK: - Update
    // ─────────────────────────────────────────

    /// Replace all mutable fields on an existing client.
    ///
    /// - Throws: `ServiceError.duplicateDNI` if the new DNI belongs to a different client.
    ///           `ServiceError.notFound` if the client has no document ID.
    func update(
        _ cliente: FBCliente,
        dni:       String,
        nombres:   String,
        apellidos: String,
        telefono:  String?,
        correo:    String?,
        direccion: String?,
        estado:    String
    ) async throws {
        guard let id = cliente.id else { throw ServiceError.notFound }
        let normalizedDNI = dni.trimmed

        if normalizedDNI != cliente.dni {
            guard try await isDNIUnique(normalizedDNI, excludingID: id) else {
                throw ServiceError.duplicateDNI
            }
        }

        var fields: [String: Any] = [
            "dni":       normalizedDNI,
            "nombres":   nombres.trimmed,
            "apellidos": apellidos.trimmed,
            "estado":    estado
        ]
        fields["telefono"]  = nonEmpty(telefono) as Any? ?? NSNull()
        fields["correo"]    = nonEmpty(correo) as Any? ?? NSNull()
        fields["direccion"] = nonEmpty(direccion) as Any? ?? NSNull()

        try await FirestoreService.update(Collections.clientes, id: id, fields)
    }

    // ─────────────────────────────────────────
    // MARK: - Delete
    // ─────────────────────────────────────────

    /// Remove a client document from Firestore (ubicacion is embedded — deleted with the doc).
    func delete(_ cliente: FBCliente) async throws {
        guard let id = cliente.id else { throw ServiceError.notFound }
        try await FirestoreService.delete(Collections.clientes, id: id)
    }

    // ─────────────────────────────────────────
    // MARK: - Private Helpers
    // ─────────────────────────────────────────

    private func nonEmpty(_ value: String?) -> String? {
        let t = value?.trimmed
        return t?.isNotBlank == true ? t : nil
    }
}
