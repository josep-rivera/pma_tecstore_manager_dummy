import SwiftUI

// ─────────────────────────────────────────────
// MARK: - ListaVentasView  (P11)
// ─────────────────────────────────────────────

struct ListaVentasView: View {

    @ObservedObject var viewModel: ListaVentasViewModel
    var onSelectVenta: ((FBVenta) -> Void)? = nil
    var onAddSale:     (() -> Void)?      = nil

    var body: some View {
        Group {
            if viewModel.ventas.isEmpty {
                emptyState
            } else {
                ventasList
            }
        }
        .sheet(isPresented: $viewModel.showDateFilter) {
            dateFilterSheet
        }
        .onAppear { viewModel.loadAll() }
    }

    // ── Ventas List ──
    private var ventasList: some View {
        List {
            // Active filter banner
            if viewModel.isDateFiltering {
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .foregroundColor(.brandPrimary)
                    Text("Filtrando: \(viewModel.startDate.displayDate) – \(viewModel.endDate.displayDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Quitar") { viewModel.clearFilter() }
                        .font(.caption)
                        .foregroundColor(.appError)
                }
                .listRowBackground(Color.brandLight.opacity(0.3))
            }

            ForEach(viewModel.ventas) { venta in
                VentaRow(venta: venta)
                    .contentShape(Rectangle())
                    .onTapGesture { onSelectVenta?(venta) }
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
    }

    // ── Empty State ──
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart.badge.plus")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No hay ventas registradas")
                .font(.headline)
                .foregroundColor(.secondary)
            Button("Registrar primera venta") { onAddSale?() }
                .buttonStyle(.borderedProminent)
                .tint(.brandPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // ── Date Filter Sheet ──
    private var dateFilterSheet: some View {
        NavigationStack {
            Form {
                Section("Rango de fechas") {
                    DatePicker("Desde", selection: $viewModel.startDate,
                               displayedComponents: .date)
                    DatePicker("Hasta", selection: $viewModel.endDate,
                               in: viewModel.startDate...,
                               displayedComponents: .date)
                }
            }
            .navigationTitle("Filtrar por fecha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { viewModel.showDateFilter = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Aplicar") {
                        viewModel.isDateFiltering = true
                        viewModel.applyDateFilter()
                        viewModel.showDateFilter = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// ─────────────────────────────────────────────
// MARK: - VentaRow
// ─────────────────────────────────────────────

struct VentaRow: View {
    let venta: FBVenta

    var body: some View {
        HStack(spacing: 12) {
            // Date circle
            VStack(spacing: 2) {
                Text(venta.saleDate.formatted(pattern: "dd"))
                    .font(.system(.title2).bold())
                    .foregroundColor(.brandPrimary)
                Text(venta.saleDate.formatted(pattern: "MMM").uppercased())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 44)
            .padding(.vertical, 8)
            .background(Color.brandLight)
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(venta.clientName)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(venta.detalles.count) producto(s) · \(venta.saleDate.displayTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(venta.totalDouble.asCurrency)
                    .font(.subheadline.bold())
                    .foregroundColor(.brandPrimary)
                Text(venta.statusValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.appSuccess.opacity(0.15))
                    .foregroundColor(.appSuccess)
                    .cornerRadius(4)
            }
        }
        .padding(12)
        .background(Color(UIColor.appSurface))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
