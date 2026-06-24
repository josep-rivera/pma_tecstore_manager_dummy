import Foundation

@MainActor
final class ListaProductosViewModel {

    // MARK: - Outputs

    var onReload: (() -> Void)?
    var onEmptyStateChanged: ((Bool) -> Void)?

    // MARK: - State

    private(set) var filteredProductos: [FBProducto] = []
    private(set) var activeFilter: Int = 0
    private var allProductos: [FBProducto] = []
    private var currentSearchText = ""

    // MARK: - Inputs

    func loadData() {
        Task { [weak self] in
            guard let self else { return }
            let productos = (try? await ProductoService.shared.fetchAll()) ?? []
            self.allProductos = productos
            self.applyFilters(searchText: self.currentSearchText)
        }
    }

    func applyFilters(searchText: String) {
        currentSearchText = searchText
        var result = searchText.isEmpty ? allProductos : allProductos.filter {
            $0.productName.localizedCaseInsensitiveContains(searchText) ||
            $0.productCode.localizedCaseInsensitiveContains(searchText) ||
            $0.categoryValue.localizedCaseInsensitiveContains(searchText)
        }
        switch activeFilter {
        case 1: result = result.filter {  $0.hasStock }
        case 2: result = result.filter { !$0.hasStock }
        default: break
        }
        filteredProductos = result
        onReload?()
        onEmptyStateChanged?(filteredProductos.isEmpty)
    }

    func setFilter(_ index: Int) {
        activeFilter = index
        applyFilters(searchText: currentSearchText)
    }

    func deleteProducto(_ producto: FBProducto) {
        Task { [weak self] in
            guard let self else { return }
            try? await ProductoService.shared.delete(producto)
            self.loadData()
        }
    }
}
