import SwiftUI

// ─────────────────────────────────────────────
// MARK: - AcercaDeView  (P17)
// ─────────────────────────────────────────────

struct AcercaDeView: View {

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        Form {
            // App Icon + Name
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.brandPrimary.opacity(0.10))
                            .frame(width: 80, height: 80)
                        Image(systemName: "storefront.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.brandPrimary)
                    }
                    Text("TecStore Manager")
                        .font(.system(.title2).bold())
                    Text("Versión \(appVersion) (\(buildNumber))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // Institución
            Section("Institución") {
                LabeledContent("Centro educativo", value: "TECSUP")
                LabeledContent("Curso", value: "Desarrollo de Apps Móviles")
                LabeledContent("Docente", value: "Juan León")
                LabeledContent("Año", value: "\(Calendar.current.component(.year, from: Date()))")
            }

            // Tecnología
            Section("Stack tecnológico") {
                LabeledContent("Lenguaje",    value: "Swift")
                LabeledContent("UI",          value: "UIKit + SwiftUI")
                LabeledContent("Base de datos", value: "Firebase Firestore")
                LabeledContent("Mapas",       value: "MapKit + CoreLocation")
                LabeledContent("Plataforma",  value: "iOS 17+")
                LabeledContent("Arquitectura", value: "MVVM")
            }

            // Funcionalidades
            Section("Funcionalidades") {
                FeatureRow(icon: "shippingbox.fill",   text: "Gestión de productos con categorías")
                FeatureRow(icon: "person.2.fill",      text: "Gestión de clientes con ubicación")
                FeatureRow(icon: "cart.fill",           text: "Registro de ventas con IGV")
                FeatureRow(icon: "chart.bar.fill",      text: "Reportes y métricas de la tienda")
                FeatureRow(icon: "magnifyingglass",     text: "Búsqueda unificada")
                FeatureRow(icon: "mappin.and.ellipse",  text: "Mapa interactivo con pin manual")
                FeatureRow(icon: "moon.fill",           text: "Modo oscuro")
            }
        }
        .navigationTitle("Acerca de")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    var body: some View {
        Label(text, systemImage: icon)
            .font(.subheadline)
            .foregroundColor(.primary)
    }
}
