import SwiftUI
import Combine

// ─────────────────────────────────────────────
// MARK: - RegistroVentaViewModel
// ─────────────────────────────────────────────

@MainActor
final class RegistroVentaViewModel: ObservableObject {

    // Data
    @Published var activeClientes:  [FBCliente]  = []
    @Published var activeProductos: [FBProducto] = []

    // Form state
    @Published var selectedCliente: FBCliente?  = nil
    @Published var cartItems:       [VentaItem] = []
    @Published var searchProducto:  String      = ""

    // UI flags
    @Published var showConfirmSheet: Bool   = false
    @Published var showError:        Bool   = false
    @Published var errorMessage:     String = ""
    @Published var saleCompleted:    Bool   = false

    // ── Derived ──

    var filteredProductos: [FBProducto] {
        let text = searchProducto.trimmed
        let base = activeProductos.filter { $0.hasStock }
        guard text.isNotBlank else { return base }
        return base.filter {
            $0.productName.localizedCaseInsensitiveContains(text) ||
            $0.productCode.localizedCaseInsensitiveContains(text)
        }
    }

    var canConfirm: Bool { selectedCliente != nil && !cartItems.isEmpty }

    var totals: (subtotal: Double, igv: Double, total: Double) {
        VentaService.shared.calculateTotals(for: cartItems)
    }

    // ── Load ──

    func loadData() {
        Task { [weak self] in
            guard let self else { return }
            async let clientes  = ClienteService.shared.fetchAll(onlyActive: true)
            async let productos = ProductoService.shared.fetchAll(onlyActive: true)
            activeClientes  = (try? await clientes)  ?? []
            activeProductos = (try? await productos) ?? []
        }
    }

    // ── Cart Operations ──

    func addToCart(_ producto: FBProducto) {
        if let idx = cartItems.firstIndex(where: { $0.producto.id == producto.id }) {
            guard cartItems[idx].cantidad < producto.stockInt else { return }
            cartItems[idx].cantidad += 1
        } else {
            cartItems.append(VentaService.shared.buildItem(product: producto, cantidad: 1))
        }
    }

    func increaseQty(_ item: VentaItem) {
        guard let idx = cartItems.firstIndex(where: { $0.id == item.id }) else { return }
        if cartItems[idx].cantidad < cartItems[idx].producto.stockInt {
            cartItems[idx].cantidad += 1
        }
    }

    func decreaseQty(_ item: VentaItem) {
        guard let idx = cartItems.firstIndex(where: { $0.id == item.id }) else { return }
        if cartItems[idx].cantidad > 1 { cartItems[idx].cantidad -= 1 }
        else                           { cartItems.remove(at: idx) }
    }

    func removeItem(_ item: VentaItem) {
        cartItems.removeAll { $0.id == item.id }
    }

    // ── Confirm ──

    func confirmSale() {
        guard let cliente = selectedCliente else { return }
        let items = cartItems
        Task { [weak self] in
            guard let self else { return }
            do {
                guard let usuario = try await AuthService.shared.currentUsuario() else { return }
                try await VentaService.shared.register(cliente: cliente, usuario: usuario, items: items)
                saleCompleted = true
            } catch let error as ServiceError {
                errorMessage = error.errorDescription ?? "Error al registrar la venta."
                showError    = true
            } catch {
                errorMessage = error.localizedDescription
                showError    = true
            }
        }
    }
}
