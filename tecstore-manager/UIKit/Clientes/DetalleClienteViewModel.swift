import Foundation

@MainActor
final class DetalleClienteViewModel {

    // MARK: - Outputs

    var onClienteUpdated: ((FBCliente) -> Void)?

    // MARK: - Inputs

    func refresh(clienteID: String) {
        guard !clienteID.isEmpty else { return }
        Task { [weak self] in
            if let updated = try? await ClienteService.shared.fetch(byID: clienteID) {
                self?.onClienteUpdated?(updated)
            }
        }
    }
}
