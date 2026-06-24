import SwiftUI
import Combine

// ─────────────────────────────────────────────
// MARK: - StockBajoViewModel
// ─────────────────────────────────────────────

@MainActor
final class StockBajoViewModel: ObservableObject {

    @Published var productos: [FBProducto] = []
    @Published var isLoading: Bool = false

    func loadProductos() {
        guard !isLoading else { return }
        isLoading = true
        Task { [weak self] in
            guard let self else { return }
            defer { isLoading = false }
            do {
                let all = try await ProductoService.shared.fetchAll()
                productos = all
                    .filter { $0.isActive && $0.stockInt <= AppConstants.lowStockThreshold }
                    .sorted { $0.stockInt < $1.stockInt }
            } catch {
                productos = []
            }
        }
    }
}
