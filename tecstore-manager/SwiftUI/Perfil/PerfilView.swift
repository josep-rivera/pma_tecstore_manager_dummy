import SwiftUI
import PhotosUI

// ─────────────────────────────────────────────
// MARK: - PerfilView  (P16)
// ─────────────────────────────────────────────

struct PerfilView: View {

    var onAcercaDe: () -> Void = {}

    @ObservedObject var viewModel: PerfilViewModel
    @State private var showChangePassword = false

    var body: some View {
        Form {

            // ── Avatar + Info ──
            Section {
                HStack(spacing: 16) {
                    PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                        avatarView
                    }
                    .onChange(of: viewModel.selectedPhotoItem) { _, _ in
                        viewModel.loadSelectedPhoto()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.user?.fullName ?? "Usuario")
                            .font(.headline)
                        Text(viewModel.user?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Registrado: \(viewModel.user?.registrationDate.displayDate ?? "")")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.appTextTertiary))
                    }
                }
                .padding(.vertical, 4)
            }

            // ── Preferencias ──
            Section("Preferencias") {
                Toggle(isOn: $viewModel.isDarkMode) {
                    Label("Modo oscuro", systemImage: "moon.fill")
                }
                .tint(.brandPrimary)
                .onChange(of: viewModel.isDarkMode) { _, _ in
                    viewModel.toggleDarkMode()
                }
            }

            // ── Seguridad ──
            Section("Seguridad") {
                Button {
                    showChangePassword = true
                } label: {
                    Label("Cambiar contraseña", systemImage: "lock.rotation")
                        .foregroundColor(.primary)
                }
            }

            // ── App Info ──
            Section("Acerca de la app") {
                Button(action: onAcercaDe) {
                    Label("Acerca de TecStore Manager", systemImage: "info.circle")
                        .foregroundColor(.primary)
                }
            }

            // ── Sesión ──
            Section {
                Button(role: .destructive) {
                    viewModel.showLogoutAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        // Change password sheet
        .sheet(isPresented: $showChangePassword) {
            CambiarPasswordSheet(viewModel: viewModel)
        }
        // Logout confirmation
        .alert("Cerrar sesión", isPresented: $viewModel.showLogoutAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Cerrar sesión", role: .destructive) { viewModel.logout() }
        } message: {
            Text("¿Estás seguro de que quieres cerrar sesión?")
        }
        // Image / sync errors
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear { viewModel.loadUser() }
    }

    // ── Avatar View ──
    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let img = viewModel.profileImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle()
                        .fill(Color.brandLight)
                        .overlay {
                            Text(viewModel.userInitial)
                                .font(.system(.title).bold())
                                .foregroundColor(.brandPrimary)
                        }
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.brandLight, lineWidth: 2))

            // Edit badge
            Image(systemName: "camera.fill")
                .font(.caption2)
                .foregroundColor(.white)
                .padding(5)
                .background(Color.brandPrimary)
                .clipShape(Circle())
                .offset(x: 2, y: 2)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - CambiarPasswordSheet
// ─────────────────────────────────────────────

struct CambiarPasswordSheet: View {

    @ObservedObject var viewModel: PerfilViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Contraseña actual", text: $viewModel.currentPwd)
                    SecureField("Nueva contraseña", text: $viewModel.newPwd)
                    SecureField("Confirmar nueva contraseña", text: $viewModel.confirmPwd)
                } footer: {
                    if !viewModel.pwdError.isEmpty {
                        Text(viewModel.pwdError)
                            .foregroundColor(.appError)
                    }
                    if viewModel.pwdSuccess {
                        Text("Contraseña cambiada exitosamente.")
                            .foregroundColor(.appSuccess)
                    }
                }
            }
            .navigationTitle("Cambiar contraseña")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        viewModel.pwdError   = ""
                        viewModel.pwdSuccess = false
                        viewModel.currentPwd = ""
                        viewModel.newPwd     = ""
                        viewModel.confirmPwd = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        viewModel.changePassword()
                        // Dismiss is triggered by watching pwdSuccess via .onChange below
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.currentPwd.isBlank || viewModel.newPwd.isBlank || viewModel.confirmPwd.isBlank)
                }
            }
        }
        .presentationDetents([.medium])
        .onChange(of: viewModel.pwdSuccess) { _, success in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
            }
        }
    }
}

