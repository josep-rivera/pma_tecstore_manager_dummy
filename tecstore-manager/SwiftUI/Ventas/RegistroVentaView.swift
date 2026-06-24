import SwiftUI

// ─────────────────────────────────────────────
// MARK: - RegistroVentaView  (P12)
// ─────────────────────────────────────────────

struct RegistroVentaView: View {

    var onSave:  () -> Void

    @ObservedObject var viewModel: RegistroVentaViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var hasAttemptedConfirm = false

    var body: some View {
        Form {
            // ── Cliente ──
            Section {
                Picker("Cliente", selection: $viewModel.selectedCliente) {
                    Text("Elige un cliente activo")
                        .foregroundColor(.secondary)
                        .tag(nil as FBCliente?)
                    ForEach(viewModel.activeClientes) { c in
                        Text(c.fullName).tag(Optional(c))
                    }
                }
            } header: {
                Text("Cliente")
            } footer: {
                if hasAttemptedConfirm && viewModel.selectedCliente == nil {
                    Text("Selecciona un cliente activo para continuar.")
                        .foregroundColor(.appError)
                }
            }

            // ── Buscar y añadir producto ──
            Section("Agregar producto") {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Buscar por nombre o código", text: $viewModel.searchProducto)
                        .autocorrectionDisabled()
                }

                if viewModel.filteredProductos.isEmpty && viewModel.searchProducto.isNotBlank {
                    Text("Sin resultados para \"\(viewModel.searchProducto)\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.filteredProductos.prefix(8)) { producto in
                        ProductPickerRow(producto: producto) {
                            viewModel.addToCart(producto)
                        }
                    }
                }
            }

            // ── Carrito ──
            if !viewModel.cartItems.isEmpty {
                Section("Carrito (\(viewModel.cartItems.count) ítem\(viewModel.cartItems.count == 1 ? "" : "s"))") {
                    ForEach(viewModel.cartItems) { item in
                        CartItemRow(item: item,
                                    onIncrease: { viewModel.increaseQty(item) },
                                    onDecrease: { viewModel.decreaseQty(item) })
                    }
                    .onDelete { idx in
                        viewModel.cartItems.remove(atOffsets: idx)
                    }
                }

                // ── Totales ──
                Section("Resumen") {
                    HStack {
                        Text("Subtotal")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.totals.subtotal.asCurrency)
                    }
                    HStack {
                        Text("IGV (18%)")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.totals.igv.asCurrency)
                    }
                    HStack {
                        Text("Total").font(.headline)
                        Spacer()
                        Text(viewModel.totals.total.asCurrency)
                            .font(.system(.title3).bold())
                            .foregroundColor(.brandPrimary)
                    }
                }

            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                hasAttemptedConfirm = true
                if viewModel.canConfirm { viewModel.showConfirmSheet = true }
            } label: {
                Label("Guardar venta", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.canConfirm ? Color.brandPrimary : Color.secondary.opacity(0.4))
                    .cornerRadius(12)
                    .padding(.horizontal, CGFloat(AppLayout.paddingLarge))
                    .padding(.vertical, CGFloat(AppLayout.padding))
            }
            .background(Color(UIColor.appGrouped).ignoresSafeArea())
        }
        // Confirmation Sheet
        .sheet(isPresented: $viewModel.showConfirmSheet) {
            ConfirmacionVentaSheet(viewModel: viewModel)
        }
        // Error alert
        .alert("Error al registrar", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.saleCompleted) { _, completed in
            if completed {
                onSave()
                dismiss()
            }
        }
        .onAppear { viewModel.loadData() }
    }
}

// ─────────────────────────────────────────────
// MARK: - ConfirmacionVentaSheet  (Sheet obligatorio del proyecto)
// ─────────────────────────────────────────────

struct ConfirmacionVentaSheet: View {

    @ObservedObject var viewModel: RegistroVentaViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Icon header
                    Image(systemName: "cart.fill.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.brandPrimary)
                        .padding(.top, 8)

                    // Cliente
                    if let c = viewModel.selectedCliente {
                        infoRow(icon: "person.fill", label: "Cliente", value: c.fullName)
                    }

                    Divider()

                    // Items
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Productos")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ForEach(viewModel.cartItems) { item in
                            HStack {
                                Text("\(item.quantityInt)×")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(width: 32, alignment: .leading)
                                Text(item.productName)
                                    .font(.subheadline)
                                Spacer()
                                Text(item.subtotalLinea.asCurrency)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.brandPrimary)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(UIColor.appSurface))
                    .cornerRadius(12)

                    // Totals summary
                    VStack(spacing: 8) {
                        totalRow("Subtotal",  viewModel.totals.subtotal.asCurrency, bold: false)
                        totalRow("IGV (18%)", viewModel.totals.igv.asCurrency,      bold: false)
                        Divider()
                        totalRow("TOTAL",     viewModel.totals.total.asCurrency,    bold: true)
                    }
                    .padding(16)
                    .background(Color(UIColor.appSurface))
                    .cornerRadius(12)

                    // Action buttons
                    VStack(spacing: 10) {
                        Button {
                            viewModel.confirmSale()
                            dismiss()
                        } label: {
                            Label("Registrar venta", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.brandPrimary)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        Button("Revisar carrito") { dismiss() }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(CGFloat(AppLayout.paddingLarge))
            }
            .navigationTitle("Confirmar venta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.brandPrimary).frame(width: 20)
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
    }

    private func totalRow(_ label: String, _ value: String, bold: Bool) -> some View {
        HStack {
            Text(label)
                .font(bold ? .headline : .subheadline)
                .foregroundColor(bold ? .primary : .secondary)
            Spacer()
            Text(value)
                .font(bold ? .headline : .subheadline)
                .foregroundColor(bold ? .brandPrimary : .primary)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Helper Row Views
// ─────────────────────────────────────────────

/// Row for product selection in RegistroVentaView
struct ProductPickerRow: View {
    let producto:  FBProducto
    let onAdd:     () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(producto.productName)
                    .font(.subheadline)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(producto.productCode)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("·")
                        .foregroundColor(.secondary)
                    Text("\(producto.stockInt) disponibles")
                        .font(.caption)
                        .foregroundColor(Color(producto.stockInt.stockUIColor))
                }
            }
            Spacer()
            Text(producto.priceDouble.asCurrency)
                .font(.subheadline.bold())
                .foregroundColor(.brandPrimary)
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(.title3))
                    .foregroundColor(.brandPrimary)
            }
            .buttonStyle(.plain)
        }
    }
}

/// Cart item row with quantity stepper
struct CartItemRow: View {
    let item:       VentaItem
    let onIncrease: () -> Void
    let onDecrease: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.productName)
                    .font(.subheadline)
                Spacer()
                Text(item.subtotalLinea.asCurrency)
                    .font(.subheadline.bold())
                    .foregroundColor(.brandPrimary)
            }
            HStack {
                Text(item.precioUnitario.asCurrency + " c/u")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                // Stepper
                HStack(spacing: 12) {
                    Button(action: onDecrease) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(.title3))
                            .foregroundColor(item.cantidad == 1 ? .appError : .brandPrimary)
                    }
                    .buttonStyle(.plain)

                    Text("\(item.cantidad)")
                        .font(.headline)
                        .frame(minWidth: 24)

                    Button(action: onIncrease) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(.title3))
                            .foregroundColor(item.cantidad >= item.producto.stockInt ? .secondary : .brandPrimary)
                    }
                    .buttonStyle(.plain)
                    .disabled(item.cantidad >= item.producto.stockInt)
                }
            }
        }
        .padding(.vertical, 6)
    }
}
