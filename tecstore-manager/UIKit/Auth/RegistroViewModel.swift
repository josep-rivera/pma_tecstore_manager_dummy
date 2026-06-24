import Foundation

// ─────────────────────────────────────────────
// MARK: - RegistroValidation
// ─────────────────────────────────────────────

struct RegistroValidation {
    let nameError: String?
    let emailError: String?
    let passwordError: String?
    let confirmError: String?

    var isValid: Bool {
        nameError == nil && emailError == nil && passwordError == nil && confirmError == nil
    }

    static let valid = RegistroValidation(nameError: nil, emailError: nil,
                                          passwordError: nil, confirmError: nil)
}

// ─────────────────────────────────────────────
// MARK: - RegistroViewModel
// ─────────────────────────────────────────────

@MainActor
final class RegistroViewModel {

    // MARK: Outputs

    var onValidationErrors: ((RegistroValidation) -> Void)?
    var onLoading: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    var onSuccess: (() -> Void)?

    // MARK: State

    private var fullName: String = ""
    private var email: String = ""
    private var password: String = ""
    private var confirmPassword: String = ""
    private var hasAttemptedSubmit = false

    // MARK: Inputs

    func updateFullName(_ value: String) {
        fullName = value.trimmed
        if hasAttemptedSubmit { validate() }
    }

    func updateEmail(_ value: String) {
        email = value.trimmed
        if hasAttemptedSubmit { validate() }
    }

    func updatePassword(_ value: String) {
        password = value
        if hasAttemptedSubmit { validate() }
    }

    func updateConfirmPassword(_ value: String) {
        confirmPassword = value
        if hasAttemptedSubmit { validate() }
    }

    func register() {
        hasAttemptedSubmit = true
        let validation = performValidation()
        onValidationErrors?(validation)
        guard validation.isValid else { return }

        onLoading?(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await AuthService.shared.register(
                    fullName: fullName,
                    email: email,
                    password: password
                )
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

    private func performValidation() -> RegistroValidation {
        let nameError: String?
        if fullName.isEmpty {
            nameError = "El nombre es requerido."
        } else if fullName.count < 3 {
            nameError = "Ingresa tu nombre completo."
        } else {
            nameError = nil
        }

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

        let confirmError: String?
        if confirmPassword.isEmpty {
            confirmError = "Confirma tu contraseña."
        } else if confirmPassword != password {
            confirmError = "Las contraseñas no coinciden."
        } else {
            confirmError = nil
        }

        return RegistroValidation(nameError: nameError,
                                  emailError: emailError,
                                  passwordError: passwordError,
                                  confirmError: confirmError)
    }
}
