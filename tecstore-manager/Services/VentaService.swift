import Foundation
import FirebaseFirestore

// ─────────────────────────────────────────────
// MARK: - VentaItem
// ─────────────────────────────────────────────

/// Represents one line in a sale: a product + quantity + price snapshot.
/// Used by `RegistroVentaViewModel` to build the cart before confirming.
struct VentaItem: Identifiable {
    let id              = UUID()            // SwiftUI list identity
    let producto:         FBProducto
    var cantidad:         Int
    var precioUnitario:   Double           // snapshot at time of sale

    /// cantidad × precioUnitario
    var subtotalLinea: Double { precioUnitario * Double(cantidad) }

    /// Display string for the subtotal.
    var subtotalDisplay: String { subtotalLinea.asCurrency }

    var productName: String { producto.productName }
    var quantityInt: Int    { cantidad }
}

// ─────────────────────────────────────────────
// MARK: - VentaService
// ─────────────────────────────────────────────

final class VentaService {

    // MARK: Singleton
    static let shared = VentaService()
    private init() {}

    private let db = Firestore.firestore()

    // ─────────────────────────────────────────
    // MARK: - Fetch
    // ─────────────────────────────────────────

    /// All sales, newest first.
    func fetchAll() async throws -> [FBVenta] {
        let snap = try await db.collection(Collections.ventas)
            .order(by: "fechaVenta", descending: true)
            .getDocuments()
        return try snap.documents.map { try $0.data(as: FBVenta.self) }
    }

    /// Single sale by document ID, or nil.
    func fetch(byID id: String) async throws -> FBVenta? {
        return try await FirestoreService.fetch(Collections.ventas, id: id, as: FBVenta.self)
    }

    /// Sales whose fechaVenta falls inside the given range (inclusive).
    func fetch(from start: Date, to end: Date) async throws -> [FBVenta] {
        let endOfDay = Calendar.current.date(
            bySettingHour: 23, minute: 59, second: 59, of: end
        ) ?? end
        let snap = try await db.collection(Collections.ventas)
            .whereField("fechaVenta", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("fechaVenta", isLessThanOrEqualTo: Timestamp(date: endOfDay))
            .order(by: "fechaVenta", descending: true)
            .getDocuments()
        return try snap.documents.map { try $0.data(as: FBVenta.self) }
    }

    /// The single most recent sale, or nil if no sales exist yet.
    func fetchMostRecent() async throws -> FBVenta? {
        let snap = try await db.collection(Collections.ventas)
            .order(by: "fechaVenta", descending: true)
            .limit(to: 1)
            .getDocuments()
        return try snap.documents.first.map { try $0.data(as: FBVenta.self) }
    }

    // ─────────────────────────────────────────
    // MARK: - Register
    // ─────────────────────────────────────────

    /// Create a new sale, record its line items, and atomically decrement stock.
    ///
    /// Business rules enforced:
    /// - Cart must contain at least one item.
    /// - Each item's stock is re-fetched from Firestore before writing.
    /// - `subtotalLinea` = cantidad × precioUnitario (snapshot).
    /// - `subtotal` = sum of all subtotalLinea.
    /// - `igv`     = subtotal × 0.18.
    /// - `total`   = subtotal + igv.
    /// - Venta doc + stock decrements are committed in a single WriteBatch.
    ///
    /// - Throws: `ServiceError.emptyCart`, `ServiceError.insufficientStock`, or Firestore errors.
    /// - Returns: The document ID of the newly created sale.
    @discardableResult
    func register(
        cliente:         FBCliente,
        usuario:         FBUsuario,
        items:           [VentaItem]
    ) async throws -> String {

        // 1. Validate cart
        guard !items.isEmpty else { throw ServiceError.emptyCart }

        // 2. Re-fetch each product to verify current stock (avoid stale cart data)
        var freshProducts: [String: FBProducto] = [:]
        for item in items {
            guard let productID = item.producto.id else {
                throw ServiceError.unknown("Producto sin ID: \(item.producto.nombre)")
            }
            guard let fresh = try await FirestoreService.fetch(
                Collections.productos, id: productID, as: FBProducto.self
            ) else {
                throw ServiceError.notFound
            }
            guard fresh.stock >= item.cantidad else {
                throw ServiceError.insufficientStock(
                    productName: fresh.nombre,
                    available: fresh.stock
                )
            }
            freshProducts[productID] = fresh
        }

        // 3. Build embedded detalles with denormalized product snapshots
        let ventaRef = db.collection(Collections.ventas).document()
        let detalles: [FBDetalleVenta] = items.compactMap { item in
            guard let productID = item.producto.id,
                  let fresh = freshProducts[productID] else { return nil }
            return FBDetalleVenta(
                id:                UUID().uuidString,
                ventaId:           ventaRef.documentID,
                productoId:        productID,
                productoNombre:    fresh.nombre,
                productoCodigo:    fresh.codigo,
                productoCategoria: fresh.categoria,
                cantidad:          item.cantidad,
                precioUnitario:    item.precioUnitario,
                subtotalLinea:     item.subtotalLinea
            )
        }

        // 4. Calculate totals
        let (subtotal, igv, total) = calculateTotals(for: items)

        // 5. Build the FBVenta
        let venta = FBVenta(
            id:             ventaRef.documentID,
            fechaVenta:     Date(),
            subtotal:       subtotal,
            igv:            igv,
            total:          total,
            estado:         "Completada",
            clienteId:      cliente.id,
            clienteNombre:  cliente.fullName,
            clienteDNI:     cliente.dni,
            usuarioId:      usuario.id,
            vendedorNombre: usuario.nombreCompleto,
            detalles:       detalles
        )

        // 6. Build WriteBatch: venta doc + detalles collection + stock decrements
        let batch = FirestoreService.batch()

        // Encode and set the venta document
        try batch.setData(from: venta, forDocument: ventaRef)

        // Write each detalle as its own document in /detalles_venta
        for detalle in detalles {
            let ref = db.collection(Collections.detallesVenta).document(detalle.id)
            try batch.setData(from: detalle, forDocument: ref)
        }

        // Decrement stock for each product
        for item in items {
            guard let productID = item.producto.id,
                  let fresh = freshProducts[productID] else { continue }
            let newStock = fresh.stock - item.cantidad
            let ref = db.collection(Collections.productos).document(productID)
            batch.updateData(["stock": newStock], forDocument: ref)
        }

        // 7. Commit atomically
        try await batch.commit()

        NotificationCenter.default.post(name: .salesDataChanged, object: nil)
        return ventaRef.documentID
    }

    // ─────────────────────────────────────────
    // MARK: - Cart Helpers
    // ─────────────────────────────────────────

    /// Build a `VentaItem` from a product using its current price as the snapshot.
    func buildItem(product: FBProducto, cantidad: Int) -> VentaItem {
        VentaItem(producto: product, cantidad: cantidad, precioUnitario: product.precio)
    }

    /// IGV (sales tax) rate applied to every sale.
    static let igvRate: Double = 0.18   // 18 %

    /// Recalculate cart totals from a list of `VentaItem`.
    func calculateTotals(for items: [VentaItem]) -> (subtotal: Double, igv: Double, total: Double) {
        let subtotal = (items.reduce(0.0) { $0 + $1.subtotalLinea } * 100).rounded() / 100
        let igv      = (subtotal * Self.igvRate * 100).rounded() / 100
        let total    = subtotal + igv
        return (subtotal, igv, total)
    }
}
