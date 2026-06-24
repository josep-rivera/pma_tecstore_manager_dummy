import Foundation

@MainActor
final class ListaClientesViewModel {

    // MARK: - Outputs

    var onReload: (() -> Void)?
    var onEmptyStateChanged: ((Bool) -> Void)?
    var onFilterActiveChanged: ((Bool) -> Void)?

    // MARK: - State

    private(set) var filteredClientes: [FBCliente] = []
    private(set) var activeFilter: Int = 0
    private var allClientes: [FBCliente] = []
    private var currentSearchText = ""

    // MARK: - Inputs

    func loadData() {
        Task { [weak self] in
            guard let self else { return }
            let clientes = (try? await ClienteService.shared.fetchAll()) ?? []
            self.allClientes = clientes
            self.applyFilters(searchText: self.currentSearchText)
        }
    }

    func applyFilters(searchText: String) {
        currentSearchText = searchText
        var result = searchText.isEmpty ? allClientes : allClientes.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) || $0.dniValue.contains(searchText)
        }
        switch activeFilter {
        case 1: result = result.filter {  $0.isActive }
        case 2: result = result.filter { !$0.isActive }
        default: break
        }
        filteredClientes = result
        onReload?()
        onEmptyStateChanged?(filteredClientes.isEmpty)
    }

    func setFilter(_ index: Int) {
        activeFilter = index
        onFilterActiveChanged?(index != 0)
        applyFilters(searchText: currentSearchText)
    }

    func deleteCliente(_ cliente: FBCliente) {
        Task { [weak self] in
            guard let self else { return }
            try? await ClienteService.shared.delete(cliente)
            self.loadData()
        }
    }
}
