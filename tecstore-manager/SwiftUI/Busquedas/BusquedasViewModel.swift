import SwiftUI
import Combine
import MapKit

// ════════════════════════════════════════════════════════════
// MARK: - BusquedasViewModel
// ════════════════════════════════════════════════════════════

@MainActor
final class BusquedasViewModel: ObservableObject {

    enum Segment: Int, CaseIterable {
        case productos = 0, clientes = 1, ventas = 2
        var title: String {
            switch self { case .productos: "Productos"; case .clientes: "Clientes"; case .ventas: "Ventas" }
        }
    }

    enum ProductoFilter: Int, CaseIterable {
        case todos, conStock, sinStock
        var title: String {
            switch self { case .todos: "Todos"; case .conStock: "Con stock"; case .sinStock: "Sin stock" }
        }
    }

    enum ClienteFilter: Int, CaseIterable {
        case todos, activos, inactivos
        var title: String {
            switch self { case .todos: "Todos"; case .activos: "Activos"; case .inactivos: "Inactivos" }
        }
    }

    @Published var searchText:       String         = ""
    @Published var selectedSegment:  Segment        = .productos
    @Published var productoFilter:   ProductoFilter = .todos
    @Published var categoriaFilter:  String         = "Todos"
    @Published var clienteFilter:    ClienteFilter  = .todos
    @Published var productos:        [FBProducto]   = []
    @Published var clientes:         [FBCliente]    = []
    @Published var ventas:           [FBVenta]      = []

    // Venta date + amount filter
    @Published var ventaStartDate:  Date   = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var ventaEndDate:    Date   = Date()
    @Published var ventaMinAmount:  String = ""

    // Detail sheets
    @Published var selectedProducto: FBProducto? = nil
    @Published var selectedCliente:  FBCliente?  = nil
    @Published var selectedVenta:    FBVenta?    = nil

    func search() {
        Task { [weak self] in
            guard let self else { return }
            let text = searchText.trimmed.lowercased()
            do {
                switch selectedSegment {
                case .productos:
                    var result = try await ProductoService.shared.fetchAll()
                    if !text.isEmpty {
                        result = result.filter {
                            $0.nombre.lowercased().contains(text) ||
                            $0.codigo.lowercased().contains(text) ||
                            $0.categoria.lowercased().contains(text)
                        }
                    }
                    switch productoFilter {
                    case .conStock:  result = result.filter { $0.hasStock }
                    case .sinStock:  result = result.filter { !$0.hasStock }
                    case .todos:     break
                    }
                    if self.categoriaFilter != "Todos" {
                        result = result.filter { $0.categoryValue == self.categoriaFilter }
                    }
                    productos = result

                case .clientes:
                    var result = try await ClienteService.shared.fetchAll()
                    if !text.isEmpty {
                        result = result.filter {
                            $0.nombres.lowercased().contains(text) ||
                            $0.apellidos.lowercased().contains(text) ||
                            $0.dni.contains(text) ||
                            ($0.correo?.lowercased().contains(text) ?? false)
                        }
                    }
                    switch clienteFilter {
                    case .activos:   result = result.filter { $0.isActive }
                    case .inactivos: result = result.filter { !$0.isActive }
                    case .todos:     break
                    }
                    clientes = result

                case .ventas:
                    var result = try await fetchVentas(from: ventaStartDate, to: ventaEndDate, minAmount: ventaMinAmount)
                    if !text.isEmpty {
                        result = result.filter {
                            $0.clienteNombre.lowercased().contains(text) ||
                            $0.clienteDNI.contains(text) ||
                            $0.vendedorNombre.lowercased().contains(text)
                        }
                    }
                    ventas = result
                }
            } catch {
                // leave previous results intact on error
            }
        }
    }

    var hasActiveFilters: Bool {
        switch selectedSegment {
        case .productos:
            return productoFilter != .todos || categoriaFilter != "Todos"
        case .clientes:
            return clienteFilter != .todos
        case .ventas:
            return ventaMinAmount.isNotBlank
        }
    }

    func resetFilters() {
        productoFilter  = .todos
        categoriaFilter = "Todos"
        clienteFilter   = .todos
        ventaMinAmount  = ""
        ventaStartDate  = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        ventaEndDate    = Date()
    }

    func applyVentaDateFilter() {
        Task { [weak self] in
            guard let self else { return }
            do {
                ventas = try await fetchVentas(from: ventaStartDate, to: ventaEndDate, minAmount: ventaMinAmount)
            } catch {
                // leave previous results intact on error
            }
        }
    }

    private func fetchVentas(from start: Date, to end: Date, minAmount: String) async throws -> [FBVenta] {
        var result = try await VentaService.shared.fetch(from: start, to: end)
        if let min = Double(minAmount), min > 0 {
            result = result.filter { $0.totalDouble >= min }
        }
        return result
    }
}
