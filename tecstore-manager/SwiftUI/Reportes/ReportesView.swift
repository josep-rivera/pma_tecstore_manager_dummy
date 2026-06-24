import SwiftUI
import Charts

// ─────────────────────────────────────────────
// MARK: - ReportesView
// ─────────────────────────────────────────────

struct ReportesView: View {

    @ObservedObject var viewModel: ReportesViewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Cargando...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let report = viewModel.report {
                reportContent(report)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Reportes")
        .onAppear { viewModel.loadReport() }
    }

    @ViewBuilder
    private func reportContent(_ report: ReporteData) -> some View {
        ScrollView {
            LazyVStack(spacing: CGFloat(AppLayout.padding)) {

                // ── Totales acumulados ──
                sectionHeader("Totales acumulados")

                HStack(spacing: CGFloat(AppLayout.padding)) {
                    ReporteCard(icon: "cart.fill",     color: .brandPrimary,
                                value: "\(report.totalVentas)",
                                label: "Ventas totales", subtitle: "todas las ventas")
                    ReporteCard(icon: "banknote.fill", color: Color.appSuccess,
                                value: report.montoTotalDisplay,
                                label: "Ingresos totales", subtitle: "suma acumulada")
                }

                HStack(spacing: CGFloat(AppLayout.padding)) {
                    ReporteCard(icon: "person.2.fill",   color: Color(UIColor.systemIndigo),
                                value: "\(report.totalClientes)",
                                label: "Clientes", subtitle: "registrados")
                    ReporteCard(icon: "shippingbox.fill", color: Color(UIColor.systemOrange),
                                value: "\(report.totalProductos)",
                                label: "Productos", subtitle: "registrados")
                }

                // ── Tendencia 14 dias ──
                if !viewModel.weeklyTrend.isEmpty {
                    sectionHeader("Ventas — últimos 14 días")
                    TrendChart(data: viewModel.weeklyTrend)
                }

                // ── Ingresos por categoria ──
                if !viewModel.byCategory.isEmpty {
                    sectionHeader("Ingresos por categoría")
                    CategoryRevenueChart(data: viewModel.byCategory)
                }

                // ── Top productos ──
                if !viewModel.topProductos.isEmpty {
                    sectionHeader("Top productos por ingresos")
                    TopProductosCard(items: viewModel.topProductos)
                }

                // ── Alertas ──
                sectionHeader("Alertas de inventario")

                if let producto = report.productoMenorStock {
                    ReporteAlertCard(
                        icon: "exclamationmark.triangle.fill", color: Color.appWarning,
                        title: "Menor stock",
                        mainText: producto.productName,
                        detail: "\(producto.stockInt) unidades · \(producto.categoryValue)"
                    )
                }

                if let venta = report.ventaMasReciente {
                    ReporteAlertCard(
                        icon: "clock.fill", color: .brandPrimary,
                        title: "Última venta",
                        mainText: venta.clientName,
                        detail: "\(venta.saleDate.displayDateTime) · \(venta.totalDouble.asCurrency)"
                    )
                }
            }
            .padding(CGFloat(AppLayout.padding))
        }
        .background(Color(UIColor.appGrouped))
        .refreshable { viewModel.loadReport() }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }
}

// ─────────────────────────────────────────────
// MARK: - Trend Chart (14 days)
// ─────────────────────────────────────────────

struct TrendChart: View {
    let data: [(date: Date, count: Int)]

    private static let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "dd/MM"; return f
    }()

    var body: some View {
        Chart(data, id: \.date) { item in
            LineMark(
                x: .value("Dia", Self.fmt.string(from: item.date)),
                y: .value("Ventas", item.count)
            )
            .foregroundStyle(Color.brandPrimary)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Dia", Self.fmt.string(from: item.date)),
                y: .value("Ventas", item.count)
            )
            .foregroundStyle(Color.brandPrimary.opacity(0.1))
            .interpolationMethod(.catmullRom)
        }
        .frame(height: 130)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5))
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 3))
        }
        .padding(CGFloat(AppLayout.padding))
        .background(Color(UIColor.appSurface))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// ─────────────────────────────────────────────
// MARK: - Category Revenue Chart
// ─────────────────────────────────────────────

struct CategoryRevenueChart: View {
    let data: [(category: String, total: Double)]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(data.prefix(5), id: \.category) { item in
                let maxVal = data.first?.total ?? 1
                HStack(spacing: 10) {
                    Text(item.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 90, alignment: .trailing)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.brandPrimary.opacity(0.12))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.brandPrimary)
                                .frame(width: geo.size.width * CGFloat(item.total / maxVal))
                        }
                    }
                    .frame(height: 18)

                    Text(item.total.asCurrency)
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                        .frame(width: 72, alignment: .leading)
                }
            }
        }
        .padding(CGFloat(AppLayout.padding))
        .background(Color(UIColor.appSurface))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// ─────────────────────────────────────────────
// MARK: - Top Productos Card
// ─────────────────────────────────────────────

struct TopProductosCard: View {
    let items: [(name: String, revenue: Double)]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(medalColor(idx).opacity(0.15))
                            .frame(width: 32, height: 32)
                        Text("\(idx + 1)")
                            .font(.caption.bold())
                            .foregroundColor(medalColor(idx))
                    }
                    Text(item.name)
                        .font(.subheadline)
                        .lineLimit(1)
                    Spacer()
                    Text(item.revenue.asCurrency)
                        .font(.subheadline.bold())
                        .foregroundColor(.brandPrimary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, CGFloat(AppLayout.padding))

                if idx < items.count - 1 {
                    Divider().padding(.horizontal)
                }
            }
        }
        .background(Color(UIColor.appSurface))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }

    private func medalColor(_ idx: Int) -> Color {
        switch idx {
        case 0: return Color(UIColor.systemYellow)
        case 1: return Color(UIColor.systemGray2)
        default: return Color(UIColor.systemBrown)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Reporte Card Components
// ─────────────────────────────────────────────

struct ReporteCard: View {
    let icon:     String
    let color:    Color
    let value:    String
    let label:    String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 16, weight: .semibold))
                }
                Spacer()
            }
            Text(value)
                .font(.system(.title2).bold())
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CGFloat(AppLayout.padding))
        .background(Color(UIColor.appSurface))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

struct ReporteAlertCard: View {
    let icon:     String
    let color:    Color
    let title:    String
    let mainText: String
    let detail:   String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Text(mainText)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(CGFloat(AppLayout.padding))
        .background(Color(UIColor.appSurface))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
