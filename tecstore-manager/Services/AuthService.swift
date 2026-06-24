import Foundation
import FirebaseAuth
import FirebaseFirestore

// ─────────────────────────────────────────────
// MARK: - ServiceError  (used by all Services)
// ─────────────────────────────────────────────

enum ServiceError: LocalizedError {
    case notFound
    case duplicateEmail
    case duplicateDNI
    case duplicateCode(String)
    case invalidCredentials
    case insufficientStock(productName: String, available: Int)
    case emptyCart
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Registro no encontrado."
        case .duplicateEmail:
            return "El correo ya está registrado. Usa otro correo."
        case .duplicateDNI:
            return "El DNI ya está registrado."
        case .duplicateCode(let code):
            return "El código '\(code)' ya existe. Elige otro código."
        case .invalidCredentials:
            return "Correo o contraseña incorrectos."
        case .insufficientStock(let name, let qty):
            return "Stock insuficiente para \"\(name)\". Disponible: \(qty) ud."
        case .emptyCart:
            return "Debe agregar al menos un producto a la venta."
        case .unknown(let msg):
            return msg.isEmpty ? "Ocurrió un error inesperado." : msg
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - AuthService
// ─────────────────────────────────────────────

final class AuthService {

    // MARK: Singleton
    static let shared = AuthService()
    private init() {}

    // ─────────────────────────────────────────
    // MARK: - Session State
    // ─────────────────────────────────────────

    /// Synchronous — Firebase Auth caches the user locally.
    var hasActiveSession: Bool {
        Auth.auth().currentUser != nil
    }

    /// Async — profile fields live in Firestore, not in Firebase Auth.
    func currentUsuario() async throws -> FBUsuario? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return try await FirestoreService.fetch(Collections.usuarios, id: uid, as: FBUsuario.self)
    }

    // ─────────────────────────────────────────
    // MARK: - Login
    // ─────────────────────────────────────────

    /// Signs in with email/password via Firebase Auth.
    ///
    /// - Throws: `ServiceError.invalidCredentials` on failure.
    func login(email: String, password: String) async throws {
        do {
            _ = try await Auth.auth().signIn(withEmail: email.lowercased().trimmed, password: password)
        } catch {
            throw ServiceError.invalidCredentials
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Register
    // ─────────────────────────────────────────

    /// Creates a Firebase Auth user and writes their profile doc to /usuarios/{uid}.
    ///
    /// - Throws: `ServiceError.duplicateEmail` if the email is already taken.
    /// - Returns: The newly created `FBUsuario`.
    @discardableResult
    func register(fullName: String, email: String, password: String) async throws -> FBUsuario {
        let normalized = email.lowercased().trimmed
        let result: AuthDataResult
        do {
            result = try await Auth.auth().createUser(withEmail: normalized, password: password)
        } catch {
            throw ServiceError.duplicateEmail
        }

        let uid = result.user.uid
        let usuario = FBUsuario(
            id: uid,
            nombreCompleto: fullName.trimmed,
            correo: normalized,
            fotoPerfil: nil,
            fechaRegistro: Date()
        )
        try await FirestoreService.set(Collections.usuarios, id: uid, usuario)
        return usuario
    }

    // ─────────────────────────────────────────
    // MARK: - Logout
    // ─────────────────────────────────────────

    /// Signs out of Firebase Auth and posts `.userDidLogout`.
    func logout() {
        try? Auth.auth().signOut()
        NotificationCenter.default.post(name: .userDidLogout, object: nil)
    }

    // ─────────────────────────────────────────
    // MARK: - Change Password
    // ─────────────────────────────────────────

    /// Reauthenticates with the current password, then updates to the new one.
    ///
    /// - Throws: `ServiceError.invalidCredentials` when reauth fails.
    func changePassword(current: String, new: String) async throws {
        guard let user = Auth.auth().currentUser,
              let email = user.email else { throw ServiceError.notFound }

        let credential = EmailAuthProvider.credential(withEmail: email, password: current)
        do {
            try await user.reauthenticate(with: credential)
        } catch {
            throw ServiceError.invalidCredentials
        }
        try await user.updatePassword(to: new)
    }

    // ─────────────────────────────────────────
    // MARK: - Update Profile
    // ─────────────────────────────────────────

    /// Updates `nombreCompleto` and/or `fotoPerfil` in the /usuarios/{uid} Firestore doc.
    func updateProfile(fullName: String, photoPath: String?) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var fields: [String: Any] = [:]
        if fullName.isNotBlank { fields["nombreCompleto"] = fullName.trimmed }
        if let p = photoPath, p.isNotBlank { fields["fotoPerfil"] = p }
        guard !fields.isEmpty else { return }
        try await FirestoreService.update(Collections.usuarios, id: uid, fields)
    }
}
