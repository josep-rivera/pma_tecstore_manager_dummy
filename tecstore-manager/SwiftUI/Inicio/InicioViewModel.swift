import SwiftUI
import Combine

// ─────────────────────────────────────────────
// MARK: - InicioViewModel
// ─────────────────────────────────────────────

@MainActor
final class InicioViewModel: ObservableObject {

    @Published var todaySalesCount:  Int     = 0
    @Published var todaySalesTotal:  Double  = 0
    @Published var outOfStockCount:  Int     = 0
    @Published var totalClients:     Int     = 0
    @Published var userName:         String? = nil

    func loadMetrics() {
        Task { [weak self] in
            guard let self else { return }
            do {
                async let today         = ReporteService.shared.todayMetrics()
                async let outOfStock    = ReporteService.shared.countOutOfStock()
                async let clientesCount = ReporteService.shared.countClientes()
                async let usuario       = AuthService.shared.currentUsuario()

                let t = try await today
                todaySalesCount = t.count
                todaySalesTotal = t.total
                outOfStockCount = try await outOfStock
                totalClients    = try await clientesCount
                userName        = try await usuario?.fullName
            } catch {
                // metrics stay at zero on error
            }
        }
    }
}
