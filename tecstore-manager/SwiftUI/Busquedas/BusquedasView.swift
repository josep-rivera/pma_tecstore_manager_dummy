import SwiftUI
import MapKit

// ════════════════════════════════════════════════════════════
// MARK: - BusquedasView
// ════════════════════════════════════════════════════════════

struct BusquedasView: View {

    @ObservedObject var viewModel: BusquedasViewModel
    @State private var showFilterSheet = false

    var body: some View {
        VStack(spacing: 0) {

            // ── Module Segment ──
            Picker("Buscar en", selection: $viewModel.selectedSegment) {
                ForEach(BusquedasViewModel.Segment.allCases, id: \.self) { seg in
                    Text(seg.title).tag(seg)
                }
            }
            .pickerStyle(.segmented)
            .padding(CGFloat(AppLayout.padding))
            .onChange(of: viewModel.selectedSegment) { _, _ in
                viewModel.resetFilters()
                viewModel.search()
            }

            // ── Search Field + Filter Button ──
            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                    TextField("Buscar \(viewModel.selectedSegment.title.lowercased())…",
                              text: $viewModel.searchText)
                        .autocorrectionDisabled()
                        .onChange(of: viewModel.searchText) { _, _ in viewModel.search() }
                    if viewModel.searchText.isNotBlank {
                        Button {
                            viewModel.searchText = ""
                            viewModel.search()
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(UIColor.appSurface))
                .cornerRadius(10)

                Button {
                    showFilterSheet = true
                } label: {
                    Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(.title3))
                        .foregroundColor(viewModel.hasActiveFilters ? .brandPrimary : .secondary)
                        .frame(width: 40, height: 40)
                        .background(Color(UIColor.appSurface))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, CGFloat(AppLayout.padding))
            .padding(.bottom, 8)

            Divider()

            // ── Results ──
            resultsList
        }
        .background(Color(UIColor.appGrouped))
        .sheet(isPresented: $showFilterSheet) {
            BusquedasFilterSheet(viewModel: viewModel) {
                viewModel.search()
                showFilterSheet = false
            }
        }
        .sheet(item: $viewModel.selectedProducto) { p in
            BusquedaProductoSheet(producto: p)
        }
        .sheet(item: $viewModel.selectedCliente) { c in
            BusquedaClienteSheet(cliente: c)
        }
        .sheet(item: $viewModel.selectedVenta) { v in
            NavigationStack { DetalleVentaView(viewModel: DetalleVentaViewModel(venta: v)) }
        }
        .navigationTitle("Búsquedas")
        .onAppear { viewModel.search() }
    }

    // ── Results ──
    @ViewBuilder
    private var resultsList: some View {
        switch viewModel.selectedSegment {
        case .productos:
            if viewModel.productos.isEmpty {
                emptyLabel("productos")
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(viewModel.productos) { p in
                            ProductoBusquedaRow(producto: p)
                                .onTapGesture { viewModel.selectedProducto = p }
                                .padding(.horizontal, CGFloat(AppLayout.padding))
                        }
                    }
                    .padding(.vertical, 10)
                }
            }

        case .clientes:
            if viewModel.clientes.isEmpty {
                emptyLabel("clientes")
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(viewModel.clientes) { c in
                            ClienteBusquedaRow(cliente: c)
                                .onTapGesture { viewModel.selectedCliente = c }
                                .padding(.horizontal, CGFloat(AppLayout.padding))
                        }
                    }
                    .padding(.vertical, 10)
                }
            }

        case .ventas:
            if viewModel.ventas.isEmpty {
                emptyLabel("ventas")
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(viewModel.ventas) { v in
                            VentaRow(venta: v)
                                .onTapGesture { viewModel.selectedVenta = v }
                                .padding(.horizontal, CGFloat(AppLayout.padding))
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
        }
    }

    private func emptyLabel(_ type: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.4))
            Text(viewModel.searchText.isBlank
                 ? "Escribe para buscar \(type)"
                 : "Sin resultados para \"\(viewModel.searchText)\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// ── Row views ──

struct ProductoBusquedaRow: View {
    let producto: FBProducto
    var body: some View {
        HStack(spacing: 12) {
            Group {
                ProductoImageView(
                    path:          producto.productImagePath,
                    categoryIcon:  producto.categoryEnum.icon,
                    categoryColor: Color(UIColor.colorForCategory(producto.categoryValue))
                )
            }
            .frame(width: 40, height: 40)
            .background(Color(UIColor.colorForCategory(producto.categoryValue)).opacity(0.15))
            .cornerRadius(8)
            .clipped()
            VStack(alignment: .leading, spacing: 3) {
                Text(producto.productName).font(.subheadline.weight(.medium)).lineLimit(1)
                Text("\(producto.productCode) · \(producto.categoryValue)")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(producto.priceDouble.asCurrency).font(.caption.bold()).foregroundColor(.brandPrimary)
                Text("\(producto.stockInt) ud.")
                    .font(.caption2)
                    .foregroundColor(Color(producto.stockInt.stockUIColor))
            }
        }
        .padding(10)
        .background(Color(UIColor.appSurface))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .opacity(producto.isActive ? 1 : 0.6)
    }
}

struct ClienteBusquedaRow: View {
    let cliente: FBCliente
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.brandLight)
                .frame(width: 40, height: 40)
                .overlay {
                    Text(String(cliente.firstNames.prefix(1)))
                        .font(.headline).foregroundColor(.brandPrimary)
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(cliente.fullName).font(.subheadline.weight(.medium)).lineLimit(1)
                Text("DNI: \(cliente.dniValue)").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Text(cliente.statusValue)
                .font(.caption2)
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(cliente.isActive ? Color.appSuccess.opacity(0.15) : Color.secondary.opacity(0.15))
                .foregroundColor(cliente.isActive ? .appSuccess : .secondary)
                .cornerRadius(4)
        }
        .padding(10)
        .background(Color(UIColor.appSurface))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .opacity(cliente.isActive ? 1 : 0.7)
    }
}

// ── Filter Sheet ──

struct BusquedasFilterSheet: View {

    @ObservedObject var viewModel: BusquedasViewModel
    var onApply: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                switch viewModel.selectedSegment {
                case .productos:
                    Section("Stock") {
                        Picker("Stock", selection: $viewModel.productoFilter) {
                            ForEach(BusquedasViewModel.ProductoFilter.allCases, id: \.self) { f in
                                Text(f.title).tag(f)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Section("Categoría") {
                        Picker("Categoría", selection: $viewModel.categoriaFilter) {
                            Text("Todas").tag("Todos")
                            ForEach(ProductCategory.allCases, id: \.rawValue) { cat in
                                Text(cat.rawValue).tag(cat.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.brandPrimary)
                    }

                case .clientes:
                    Section("Estado") {
                        Picker("Estado", selection: $viewModel.clienteFilter) {
                            ForEach(BusquedasViewModel.ClienteFilter.allCases, id: \.self) { f in
                                Text(f.title).tag(f)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                case .ventas:
                    Section("Rango de fechas") {
                        DatePicker("Desde", selection: $viewModel.ventaStartDate,
                                   displayedComponents: .date)
                        DatePicker("Hasta", selection: $viewModel.ventaEndDate,
                                   in: viewModel.ventaStartDate...,
                                   displayedComponents: .date)
                    }
                    Section("Monto mínimo") {
                        HStack {
                            Image(systemName: "dollarsign.circle")
                                .foregroundColor(.secondary)
                            TextField("Ej: 50.00", text: $viewModel.ventaMinAmount)
                                .keyboardType(.decimalPad)
                        }
                    }
                }
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Limpiar") {
                        viewModel.resetFilters()
                        onApply()
                    }
                    .foregroundColor(.appError)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Aplicar") { onApply() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// ── Detail sheets ──

struct BusquedaProductoSheet: View {
    let producto: FBProducto
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("Información") {
                    LabeledContent("Código",    value: producto.productCode)
                    LabeledContent("Categoría", value: producto.categoryValue)
                    LabeledContent("Precio",    value: producto.priceDouble.asCurrency)
                    LabeledContent("Stock",     value: "\(producto.stockInt) unidades")
                    LabeledContent("Estado",    value: producto.statusValue)
                }
            }
            .navigationTitle(producto.productName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct BusquedaClienteSheet: View {
    let cliente: FBCliente
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("Información") {
                    LabeledContent("DNI",       value: cliente.dniValue)
                    LabeledContent("Teléfono",  value: cliente.phoneNumber ?? "—")
                    LabeledContent("Correo",    value: cliente.emailValue  ?? "—")
                    LabeledContent("Estado",    value: cliente.statusValue)
                }
                if let loc = cliente.ubicacion, loc.hasValidCoordinates {
                    Section("Ubicación") {
                        Map(position: .constant(.region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude),
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )))) {
                            Marker(cliente.fullName,
                                   coordinate: CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude))
                                .tint(Color.brandPrimary)
                        }
                        .frame(height: 180)
                        .cornerRadius(10)
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                        if let ref = loc.reference {
                            LabeledContent("Dirección", value: ref)
                        }
                    }
                } else if let dir = cliente.addressValue {
                    Section("Ubicación") {
                        LabeledContent("Dirección", value: dir)
                    }
                }
            }
            .navigationTitle(cliente.fullName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }
}
