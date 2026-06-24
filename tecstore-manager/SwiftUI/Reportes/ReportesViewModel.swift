import SwiftUI
import Charts
import Combine

// ─────────────────────────────────────────────
// MARK: - ReportesViewModel
// ─────────────────────────────────────────────

@MainActor
final class ReportesViewModel: ObservableObject {

    @Published var report:          ReporteData? = nil
    @Published var byCategory:      [(category: String, total: Double)] = []
    @Published var topProductos:    [(name: String, revenue: Double)]   = []
    @Published var weeklyTrend:     [(date: Date, count: Int)]          = []
    @Published var isLoading:       Bool = false

    func loadReport() {
        isLoading = true
        Task { [weak self] in
            guard let self else { return }
            async let report      = ReporteService.shared.generateReport()
            async let byCategory  = ReporteService.shared.revenueByCategory()
            async let topProductos = ReporteService.shared.topProductosByRevenue(limit: AppConstants.topProductosLimit)
            async let weeklyTrend = ReporteService.shared.salesByDay(lastDays: AppConstants.salesTrendWindowDays)
            self.report       = try? await report
            self.byCategory   = (try? await byCategory)   ?? []
            self.topProductos = (try? await topProductos) ?? []
            self.weeklyTrend  = (try? await weeklyTrend)  ?? []
            self.isLoading    = false
        }
    }
}
