import Foundation

// ─────────────────────────────────────────────
// MARK: - LoginValidation
// ─────────────────────────────────────────────

struct LoginValidation {
    let emailError: String?
    let passwordError: String?

    var isValid: Bool {
        emailError == nil && passwordError == nil
    }

    static let valid = LoginValidation(emailError: nil, passwordError: nil)
}

// ─────────────────────────────────────────────
// MARK: - LoginViewModel
// ─────────────────────────────────────────────

@MainActor
final class LoginViewModel {

    // MARK: Outputs

    var onValidationErrors: ((LoginValidation) -> Void)?
    var onLoading: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    var onSuccess: (() -> Void)?

    // MARK: State

    private var email: String = ""
    private var password: String = ""
    private var hasAttemptedSubmit = false

    // MARK: Inputs

    func updateEmail(_ value: String) {
        email = value.trimmed
        if hasAttemptedSubmit { validate() }
    }

    func updatePassword(_ value: String) {
        password = value
        if hasAttemptedSubmit { validate() }
    }

    func login() {
        hasAttemptedSubmit = true
        let validation = performValidation()
        onValidationErrors?(validation)
        guard validation.isValid else { return }

        onLoading?(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await AuthService.shared.login(email: email, password: password)
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

    // MARK: Private

    private func validate() {
        onValidationErrors?(performValidation())
    }

    private func performValidation() -> LoginValidation {
        let emailError: String?
        if email.isEmpty {
            emailError = "El correo es requerido."
        } else if !email.isValidEmail {
            emailError = "Formato de correo inválido."
        } else {
            emailError = nil
        }

        let passwordError: String?
        if password.isEmpty {
            passwordError = "La contraseña es requerida."
        } else if password.count < AppConstants.passwordMinLength {
            passwordError = "Mínimo \(AppConstants.passwordMinLength) caracteres."
        } else {
            passwordError = nil
        }

        return LoginValidation(emailError: emailError, passwordError: passwordError)
    }
}
