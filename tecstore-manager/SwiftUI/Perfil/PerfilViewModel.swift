import SwiftUI
import Combine
import PhotosUI

// ─────────────────────────────────────────────
// MARK: - PerfilViewModel
// ─────────────────────────────────────────────

@MainActor
final class PerfilViewModel: ObservableObject {

    @Published var user:           FBUsuario? = nil
    @Published var isDarkMode:     Bool       = UserDefaults.standard.bool(forKey: UserDefaultsKeys.darkModeEnabled)
    @Published var profileImage:   UIImage?   = nil

    // Photo picker state (kept in the VM, not the View)
    @Published var selectedPhotoItem: PhotosPickerItem? = nil

    // Password change state
    @Published var currentPwd:  String = ""
    @Published var newPwd:      String = ""
    @Published var confirmPwd:  String = ""
    @Published var pwdError:    String = ""
    @Published var pwdSuccess:  Bool   = false

    // Alerts
    @Published var showLogoutAlert:  Bool   = false
    @Published var showErrorAlert:   Bool   = false
    @Published var errorMessage:     String = ""

    func loadUser() {
        Task { [weak self] in
            guard let self else { return }
            do {
                user = try await AuthService.shared.currentUsuario()
                if let path = user?.profileImagePath {
                    profileImage = UIImage.fromDocuments(named: path)
                }
            } catch {
                // user stays nil
            }
        }
    }

    func toggleDarkMode() {
        SceneDelegate.shared?.setDarkMode(isDarkMode)
    }

    /// Handles the item returned by `PhotosPicker`.
    func loadSelectedPhoto() {
        guard let item = selectedPhotoItem else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    return
                }
                saveProfilePhoto(image)
            } catch {
                errorMessage = "No se pudo cargar la foto seleccionada."
                showErrorAlert = true
            }
        }
    }

    func saveProfilePhoto(_ image: UIImage) {
        let resized  = image.resized(maxDimension: AppConstants.profileImageMaxDimension)
        let fileName = "profile_\(user?.id ?? "unknown").jpg"
        guard let savedPath = resized.saveToDocuments(named: fileName) else {
            errorMessage = "No se pudo guardar la foto en el dispositivo."
            showErrorAlert = true
            return
        }
        profileImage = resized
        Task { [weak self] in
            guard let self else { return }
            do {
                try await AuthService.shared.updateProfile(fullName: user?.fullName ?? "", photoPath: savedPath)
                user = try await AuthService.shared.currentUsuario()
            } catch {
                errorMessage = "No se pudo sincronizar la foto de perfil."
                showErrorAlert = true
            }
        }
    }

    func changePassword() {
        pwdError = ""
        guard newPwd.count >= AppConstants.passwordMinLength else {
            pwdError = "La nueva contraseña debe tener al menos \(AppConstants.passwordMinLength) caracteres."
            return
        }
        guard newPwd == confirmPwd else {
            pwdError = "Las contraseñas no coinciden."
            return
        }
        Task { [weak self] in
            guard let self else { return }
            do {
                try await AuthService.shared.changePassword(current: currentPwd, new: newPwd)
                pwdSuccess = true
                currentPwd = ""
                newPwd     = ""
                confirmPwd = ""
            } catch let error as ServiceError {
                pwdError = error.errorDescription ?? "Error al cambiar contraseña."
            } catch {
                pwdError = error.localizedDescription
            }
        }
    }

    func logout() {
        AuthService.shared.logout()
    }

    var userInitial: String {
        String(user?.fullName.prefix(1) ?? "?").uppercased()
    }
}
