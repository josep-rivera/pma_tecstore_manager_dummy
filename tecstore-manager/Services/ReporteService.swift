import Foundation
import FirebaseFirestore

// ─────────────────────────────────────────────
// MARK: - ReporteData
// ─────────────────────────────────────────────

/// Snapshot of all dashboard metrics. Created by `ReporteService.generateReport()`.
struct ReporteData {
    let totalVentas:        Int           // 1. Total de ventas registradas
    let montoTotal:         Double        // 2. Monto total vendido (suma de totales)
    let totalClientes:      Int           // 3. Total de clientes registrados
    let totalProductos:     Int           // 4. Total de productos registrados
    let productoMenorStock: FBProducto?  // 5. Producto con menor stock (activo)
    let ventaMasReciente:   FBVenta?     // 6. Venta más reciente

    /// True if there is at least one sale in the database.
    var hasSales: Bool { totalVentas > 0 }

    /// Display string for `montoTotal`.
    var montoTotalDisplay: String { montoTotal.asCurrency }
}

// ─────────────────────────────────────────────
// MARK: - ReporteService
// ─────────────────────────────────────────────

final class ReporteService {

    // MARK: Singleton
    static let shared = ReporteService()
    private init() {}

    private let db = Firestore.firestore()

    // ─────────────────────────────────────────
    // MARK: - Full Report
    // ─────────────────────────────────────────

    /// Compute all 6 metrics in one async call.
    func generateReport() async throws -> ReporteData {
        async let ventas    = fetchAllVentas()
        async let clientes  = countClientes()
        async let productos = countProductos()
        async let menorStock  = fetchProductoMenorStock()

        let allVentas = try await ventas
        let reciente  = allVentas.first   // already sorted newest-first by fetchAllVentas()
        let monto     = allVentas.reduce(0.0) { $0 + $1.total }

        return ReporteData(
            totalVentas:        allVentas.count,
            montoTotal:         monto,
            totalClientes:      try await clientes,
            totalProductos:     try await productos,
            productoMenorStock: try await menorStock,
            ventaMasReciente:   reciente
        )
    }

    // ─────────────────────────────────────────
    // MARK: - Individual Metrics
    // ─────────────────────────────────────────

    func countVentas() async throws -> Int {
        let snap = try await db.collection(Collections.ventas).getDocuments()
        return snap.count
    }

    func sumMontoTotal() async throws -> Double {
        let ventas = try await fetchAllVentas()
        return ventas.reduce(0.0) { $0 + $1.total }
    }

    func countClientes() async throws -> Int {
        let snap = try await db.collection(Collections.clientes).getDocuments()
        return snap.count
    }

    func countProductos() async throws -> Int {
        let snap = try await db.collection(Collections.productos).getDocuments()
        return snap.count
    }

    func fetchProductoMenorStock() async throws -> FBProducto? {
        let snap = try await db.collection(Collections.productos).getDocuments()
        let all = try snap.documents.map { try $0.data(as: FBProducto.self) }
        return all.filter { $0.isActive }.min(by: { $0.stock < $1.stock })
    }

    func fetchVentaMasReciente() async throws -> FBVenta? {
        let snap = try await db.collection(Collections.ventas)
            .order(by: "fechaVenta", descending: true)
            .limit(to: 1)
            .getDocuments()
        return try snap.documents.first.map { try $0.data(as: FBVenta.self) }
    }

    // ─────────────────────────────────────────
    // MARK: - Quick Metrics  (for InicioView cards)
    // ─────────────────────────────────────────

    /// Counts of today's sales and their total amount.
    func todayMetrics() async throws -> (count: Int, total: Double) {
        let today    = Date().startOfDay
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        let snap = try await db.collection(Collections.ventas)
            .whereField("fechaVenta", isGreaterThanOrEqualTo: Timestamp(date: today))
            .whereField("fechaVenta", isLessThan: Timestamp(date: tomorrow))
            .getDocuments()
        let ventas = try snap.documents.map { try $0.data(as: FBVenta.self) }
        return (ventas.count, ventas.reduce(0) { $0 + $1.total })
    }

    /// Number of active products whose stock is 0.
    func countOutOfStock() async throws -> Int {
        let snap = try await db.collection(Collections.productos).getDocuments()
        let all = try snap.documents.map { try $0.data(as: FBProducto.self) }
        return all.filter { $0.isActive && $0.stock == 0 }.count
    }

    /// Total revenue grouped by product category, highest first.
    /// Uses the denormalized `productoCategoria` field in each embedded `FBDetalleVenta`.
    func revenueByCategory() async throws -> [(category: String, total: Double)] {
        let ventas = try await fetchAllVentas()
        var dict: [String: Double] = [:]
        for venta in ventas {
            for detalle in venta.detalles {
                dict[detalle.productoCategoria, default: 0] += detalle.subtotalLinea
            }
        }
        return dict
            .filter { !$0.key.isEmpty }
            .map { (category: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }

    /// Top products by total revenue.
    func topProductosByRevenue(limit: Int = 3) async throws -> [(name: String, revenue: Double)] {
        let ventas = try await fetchAllVentas()
        var dict: [String: Double] = [:]
        for venta in ventas {
            for detalle in venta.detalles {
                dict[detalle.productoNombre, default: 0] += detalle.subtotalLinea
            }
        }
        return dict
            .map { (name: $0.key, revenue: $0.value) }
            .sorted { $0.revenue > $1.revenue }
            .prefix(limit)
            .map { $0 }
    }

    /// Sales count per day for the last `lastDays` days (oldest → newest).
    func salesByDay(lastDays: Int = 7) async throws -> [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let today    = Date().startOfDay
        let oldest   = calendar.date(byAdding: .day, value: -(lastDays - 1), to: today) ?? today

        let snap = try await db.collection(Collections.ventas)
            .whereField("fechaVenta", isGreaterThanOrEqualTo: Timestamp(date: oldest))
            .getDocuments()
        let ventas = try snap.documents.map { try $0.data(as: FBVenta.self) }

        return (0..<lastDays).reversed().map { offset in
            let day  = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let next = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let count = ventas.filter { $0.fechaVenta >= day && $0.fechaVenta < next }.count
            return (day, count)
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Private Helpers
    // ─────────────────────────────────────────

    private func fetchAllVentas() async throws -> [FBVenta] {
        let snap = try await db.collection(Collections.ventas)
            .order(by: "fechaVenta", descending: true)
            .getDocuments()
        return try snap.documents.map { try $0.data(as: FBVenta.self) }
    }
}
