import SwiftUI
import Combine

// ─────────────────────────────────────────────
// MARK: - ListaVentasViewModel
// ─────────────────────────────────────────────

@MainActor
final class ListaVentasViewModel: ObservableObject {

    @Published var ventas:          [FBVenta] = []
    @Published var allVentas:       [FBVenta] = []
    @Published var isDateFiltering: Bool    = false
    @Published var showDateFilter:  Bool    = false
    @Published var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var endDate:   Date = Date()

    func loadAll() {
        Task { [weak self] in
            guard let self else { return }
            let all = (try? await VentaService.shared.fetchAll()) ?? []
            allVentas = all; ventas = all
        }
    }

    func applySearch(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        ventas = trimmed.isEmpty
            ? allVentas
            : allVentas.filter { $0.clientName.localizedCaseInsensitiveContains(trimmed) }
    }

    func applyDateFilter() {
        Task { [weak self] in
            guard let self else { return }
            let all = (try? await VentaService.shared.fetch(from: startDate, to: endDate)) ?? []
            allVentas = all; ventas = all
        }
    }

    func clearFilter() {
        isDateFiltering = false
        loadAll()
    }
}
