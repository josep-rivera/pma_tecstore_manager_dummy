import Foundation
import FirebaseFirestore

// ─────────────────────────────────────────────
// MARK: - ProductoService
// ─────────────────────────────────────────────

final class ProductoService {

    // MARK: Singleton
    static let shared = ProductoService()
    private init() {}

    private let db = Firestore.firestore()

    // ─────────────────────────────────────────
    // MARK: - Fetch
    // ─────────────────────────────────────────

    /// All products, sorted by name. Client-side filter avoids composite index requirement.
    func fetchAll(onlyActive: Bool = false) async throws -> [FBProducto] {
        let snap = try await db.collection(Collections.productos).getDocuments()
        var all = try snap.documents.map { try $0.data(as: FBProducto.self) }
        if onlyActive { all = all.filter { $0.isActive } }
        return all.sorted { $0.nombre.localizedCompare($1.nombre) == .orderedAscending }
    }

    /// Single product by document ID, or nil if not found.
    func fetch(byID id: String) async throws -> FBProducto? {
        return try await FirestoreService.fetch(Collections.productos, id: id, as: FBProducto.self)
    }

    // ─────────────────────────────────────────
    // MARK: - Low Stock
    // ─────────────────────────────────────────

    /// Active products whose stock is at or below the given threshold, sorted by stock ascending.
    func fetchLowStock(threshold: Int = AppConstants.lowStockThreshold) async throws -> [FBProducto] {
        let all = try await fetchAll(onlyActive: true)
        return all.filter { $0.stock <= threshold }.sorted { $0.stock < $1.stock }
    }

    /// The single active product with the fewest units.
    func fetchLowestStockProduct() async throws -> FBProducto? {
        let all = try await fetchAll(onlyActive: true)
        return all.min(by: { $0.stock < $1.stock })
    }

    // ─────────────────────────────────────────
    // MARK: - Code Generation
    // ─────────────────────────────────────────

    func generateCode(for category: String) async throws -> String {
        let prefix = categoryPrefix(for: category)
        let snap = try await db.collection(Collections.productos)
            .whereField("codigo", isGreaterThanOrEqualTo: prefix + "-")
            .whereField("codigo", isLessThan: prefix + "-\u{FFFF}")
            .getDocuments()
        let maxNum = snap.documents.compactMap { doc -> Int? in
            guard let code = doc.data()["codigo"] as? String else { return nil }
            let parts = code.split(separator: "-")
            return parts.count == 2 ? Int(parts[1]) : nil
        }.max() ?? 0
        return String(format: "%@-%03d", prefix, maxNum + 1)
    }

    private func categoryPrefix(for category: String) -> String {
        switch category {
        case "Electrónica": return "ELEC"
        case "Ropa":        return "ROPA"
        case "Alimentos":   return "ALIM"
        case "Limpieza":    return "LIMP"
        case "Hogar":       return "HOGAR"
        case "Tecnología":  return "TEC"
        case "Deportes":    return "DEPO"
        case "Otros":       return "OTROS"
        default:            return "PRD"
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Validation
    // ─────────────────────────────────────────

    /// True when no other product uses this code (case-insensitive check done on normalized input).
    func isCodeUnique(_ code: String, excludingID: String? = nil) async throws -> Bool {
        let normalizedCode = code.trimmed.uppercased()
        let snap = try await db.collection(Collections.productos)
            .whereField("codigo", isEqualTo: normalizedCode)
            .limit(to: 1)
            .getDocuments()
        guard let doc = snap.documents.first else { return true }
        // If this document is the one being edited, it's still unique.
        return doc.documentID == excludingID
    }

    // ─────────────────────────────────────────
    // MARK: - Create
    // ─────────────────────────────────────────

    /// Insert a new product in Firestore.
    ///
    /// - Throws: `ServiceError.duplicateCode` if the code is already taken.
    /// - Returns: The document ID of the newly created product.
    @discardableResult
    func create(
        code:      String,
        name:      String,
        category:  String,
        price:     Double,
        stock:     Int,
        photoPath: String? = nil
    ) async throws -> String {
        let normalizedCode = code.trimmed.uppercased()

        guard try await isCodeUnique(normalizedCode) else {
            throw ServiceError.duplicateCode(normalizedCode)
        }

        let producto = FBProducto(
            id:            nil,
            codigo:        normalizedCode,
            nombre:        name.trimmed,
            categoria:     category,
            precio:        price,
            stock:         max(0, stock),
            fotoProducto:  photoPath?.trimmed.isNotBlank == true ? photoPath : nil,
            estado:        "Activo",
            fechaRegistro: Date()
        )
        return try await FirestoreService.add(Collections.productos, producto)
    }

    // ─────────────────────────────────────────
    // MARK: - Update
    // ─────────────────────────────────────────

    /// Replace all mutable fields on an existing product.
    ///
    /// - Throws: `ServiceError.duplicateCode` if the new code belongs to a different product.
    ///           `ServiceError.notFound` if the product has no document ID.
    func update(
        _ producto: FBProducto,
        code:       String,
        name:       String,
        category:   String,
        price:      Double,
        stock:      Int,
        photoPath:  String?,
        estado:     String
    ) async throws {
        guard let id = producto.id else { throw ServiceError.notFound }
        let normalizedCode = code.trimmed.uppercased()

        if normalizedCode != producto.codigo {
            guard try await isCodeUnique(normalizedCode, excludingID: id) else {
                throw ServiceError.duplicateCode(normalizedCode)
            }
        }

        let fields: [String: Any] = [
            "codigo":        normalizedCode,
            "nombre":        name.trimmed,
            "categoria":     category,
            "precio":        price,
            "stock":         max(0, stock),
            "fotoProducto":  photoPath?.trimmed.isNotBlank == true ? photoPath as Any : NSNull(),
            "estado":        estado
        ]
        try await FirestoreService.update(Collections.productos, id: id, fields)
    }

    // ─────────────────────────────────────────
    // MARK: - Delete
    // ─────────────────────────────────────────

    /// Remove a product document from Firestore.
    func delete(_ producto: FBProducto) async throws {
        guard let id = producto.id else { throw ServiceError.notFound }
        try await FirestoreService.delete(Collections.productos, id: id)
    }
}
