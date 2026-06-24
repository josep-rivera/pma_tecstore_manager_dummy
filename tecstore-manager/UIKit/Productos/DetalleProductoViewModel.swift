import Foundation

@MainActor
final class DetalleProductoViewModel {

    // MARK: - Outputs

    var onProductoUpdated: ((FBProducto) -> Void)?

    // MARK: - Inputs

    func refresh(productoID: String) {
        guard !productoID.isEmpty else { return }
        Task { [weak self] in
            if let updated = try? await ProductoService.shared.fetch(byID: productoID) {
                self?.onProductoUpdated?(updated)
            }
        }
    }
}
