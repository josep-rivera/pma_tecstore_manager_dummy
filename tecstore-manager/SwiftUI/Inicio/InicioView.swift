import SwiftUI
import Combine

// ─────────────────────────────────────────────
// MARK: - InicioView
// ─────────────────────────────────────────────

struct InicioView: View {

    @ObservedObject var viewModel: InicioViewModel

    var onBusquedas:  (() -> Void)? = nil
    var onReportes:   (() -> Void)? = nil
    var onStockBajo:  (() -> Void)? = nil
    var onNuevaVenta: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: CGFloat(AppLayout.paddingLarge)) {

                welcomeHeader

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: CGFloat(AppLayout.padding)
                ) {
                    MetricCard(icon: "cart.fill",   color: .brandPrimary,
                               value: "\(viewModel.todaySalesCount)", label: "Ventas hoy")
                    MetricCard(icon: "banknote.fill", color: Color.appSuccess,
                               value: viewModel.todaySalesTotal.asCurrency, label: "Ingresos hoy")
                    MetricCard(icon: "exclamationmark.triangle.fill", color: Color.appWarning,
                               value: "\(viewModel.outOfStockCount)", label: "Sin stock")
                    MetricCard(icon: "person.2.fill", color: Color(UIColor.systemIndigo),
                               value: "\(viewModel.totalClients)", label: "Clientes")
                }
                .padding(.horizontal, CGFloat(AppLayout.padding))

                shortcutsSection
            }
            .padding(.vertical, CGFloat(AppLayout.padding))
        }
        .background(Color(UIColor.appGrouped))
        .navigationTitle("Inicio")
        .onAppear { viewModel.loadMetrics() }
        .onReceive(NotificationCenter.default.publisher(for: .salesDataChanged)) { _ in
            viewModel.loadMetrics()
        }
    }

    // ── Welcome ──
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bienvenido")
                    .font(.system(.title2).bold())
                if let name = viewModel.userName {
                    Text(name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Image(systemName: "storefront.fill")
                .font(.system(.title))
                .foregroundColor(.brandPrimary)
        }
        .padding(CGFloat(AppLayout.paddingLarge))
        .background(Color(UIColor.appSurface))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(.horizontal, CGFloat(AppLayout.padding))
    }

    // ── Shortcuts ──
    private var shortcutsSection: some View {
        VStack(spacing: CGFloat(AppLayout.paddingSmall)) {
            Text("Accesos rápidos")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, CGFloat(AppLayout.padding))

            Button { onBusquedas?() } label: {
                ShortcutCard(icon: "magnifyingglass", title: "Búsquedas",
                             subtitle: "Buscar en productos, clientes y ventas",
                             color: .brandPrimary)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, CGFloat(AppLayout.padding))

            Button { onReportes?() } label: {
                ShortcutCard(icon: "chart.bar.fill", title: "Reportes",
                             subtitle: "Métricas y tendencias de la tienda",
                             color: Color.appSuccess)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, CGFloat(AppLayout.padding))

            Button { onNuevaVenta?() } label: {
                ShortcutCard(icon: "cart.badge.plus", title: "Nueva venta",
                             subtitle: "Registrar una venta rápidamente",
                             color: Color(UIColor.systemOrange))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, CGFloat(AppLayout.padding))

            Button { onStockBajo?() } label: {
                ShortcutCard(icon: "exclamationmark.triangle.fill", title: "Stock bajo",
                             subtitle: "Productos con \(AppConstants.lowStockThreshold) unidades o menos",
                             color: Color.appWarning)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, CGFloat(AppLayout.padding))
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Reusable Card Components
// ─────────────────────────────────────────────

struct MetricCard: View {
    let icon:   String
    let color:  Color
    let value:  String
    let label:  String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(.title3))
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(.title2).bold())
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(CGFloat(AppLayout.padding))
        .background(Color(UIColor.appSurface))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

struct ShortcutCard: View {
    let icon:     String
    let title:    String
    let subtitle: String
    let color:    Color

    var body: some View {
        HStack(spacing: CGFloat(AppLayout.padding)) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(.title3))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(UIColor.appTextTertiary))
        }
        .padding(CGFloat(AppLayout.padding))
        .background(Color(UIColor.appSurface))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}
