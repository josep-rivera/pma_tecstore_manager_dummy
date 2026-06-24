import SwiftUI

// ─────────────────────────────────────────────
// MARK: - DetalleVentaView  (P13)
// Shared between ListaVentasView and BusquedasView.
// ─────────────────────────────────────────────

struct DetalleVentaView: View {

    @ObservedObject var viewModel: DetalleVentaViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: CGFloat(AppLayout.padding)) {
                headerCard
                participantesCard
                productosCard
                resumenCard
            }
            .padding(CGFloat(AppLayout.paddingLarge))
        }
        .background(Color(UIColor.appGrouped))
    }

    // ── Header: status + date ──
    private var headerCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 52))
                .foregroundColor(.appSuccess)
            Text(viewModel.venta.statusValue)
                .font(.system(.title2).bold())
                .foregroundColor(.appSuccess)
            Text(viewModel.venta.saleDate.displayDateTime)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(UIColor.appSurface))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
    }

    // ── Participantes ──
    private var participantesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader("Participantes")
            Divider()
            infoRow(icon: "person.fill",        label: "Cliente",  value: viewModel.venta.clientName)
            Divider().padding(.leading, CGFloat(AppLayout.paddingLarge))
            infoRow(icon: "person.badge.key.fill", label: "Vendedor", value: viewModel.venta.sellerName)
        }
        .background(Color(UIColor.appSurface))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
    }

    // ── Productos ──
    private var productosCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader("Productos (\(viewModel.venta.detalles.count))")
            Divider()
            ForEach(Array(viewModel.venta.detalles.enumerated()), id: \.offset) { idx, detalle in
                if idx > 0 {
                    Divider().padding(.leading, CGFloat(AppLayout.paddingLarge))
                }
                HStack(alignment: .top, spacing: 12) {
                    Text("\(detalle.quantityInt)×")
                        .font(.headline)
                        .foregroundColor(.brandPrimary)
                        .frame(width: 32, alignment: .leading)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(detalle.productName)
                            .font(.subheadline.weight(.medium))
                        Text("\(detalle.unitPriceDouble.asCurrency) c/u · \(detalle.productCode)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(detalle.lineTotalDouble.asCurrency)
                        .font(.subheadline.bold())
                        .foregroundColor(.brandPrimary)
                }
                .padding(.horizontal, CGFloat(AppLayout.paddingLarge))
                .padding(.vertical, 12)
            }
        }
        .background(Color(UIColor.appSurface))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
    }

    // ── Resumen financiero ──
    private var resumenCard: some View {
        VStack(spacing: 0) {
            cardHeader("Resumen financiero")
            Divider()
            resumenRow("Subtotal", viewModel.venta.subtotalDouble.asCurrency)
            Divider().padding(.leading, CGFloat(AppLayout.paddingLarge))
            resumenRow("IGV (18%)", viewModel.igv.asCurrency)
            Divider()
            // Total — visually prominent
            HStack {
                Text("TOTAL")
                    .font(.system(.title3).bold())
                Spacer()
                Text(viewModel.venta.totalDouble.asCurrency)
                    .font(.system(.title3).bold())
                    .foregroundColor(.brandPrimary)
            }
            .padding(.horizontal, CGFloat(AppLayout.paddingLarge))
            .padding(.vertical, 16)
        }
        .background(Color(UIColor.appSurface))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
    }

    // ── Helpers ──
    private func cardHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, CGFloat(AppLayout.paddingLarge))
            .padding(.vertical, 10)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.brandPrimary)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, CGFloat(AppLayout.paddingLarge))
        .padding(.vertical, 14)
    }

    private func resumenRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, CGFloat(AppLayout.paddingLarge))
        .padding(.vertical, 10)
    }
}
