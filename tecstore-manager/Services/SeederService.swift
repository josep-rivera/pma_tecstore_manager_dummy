import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - DummyJSON response types

private struct DJProductsResponse: Decodable {
    let products: [DJProduct]
}

private struct DJProduct: Decodable {
    let id: Int
    let title: String
    let category: String
    let price: Double
    let stock: Int
    let thumbnail: String
}

private struct DJUsersResponse: Decodable {
    let users: [DJUser]
}

private struct DJUser: Decodable {
    let id: Int
    let firstName: String
    let lastName: String
    let phone: String
    let email: String
    let address: DJAddress
}

private struct DJAddress: Decodable {
    let address: String
    let coordinates: DJCoordinates
}

private struct DJCoordinates: Decodable {
    let lat: Double
    let lng: Double
}

// MARK: - SeederService

final class SeederService {

    static let shared = SeederService()
    private init() {}

    private let db = Firestore.firestore()
    private let seededKey = "seederCompleted_v1_dummy"

    // Maps dummyjson categories to app categories
    private static let categoryMap: [String: String] = [
        "smartphones":                       "Tecnología",
        "laptops":                           "Tecnología",
        "tablets":                           "Tecnología",
        "mobile-accessories":                "Tecnología",
        "computer-accessories-peripherals":  "Tecnología",
        "mens-shirts":                       "Ropa",
        "womens-dresses":                    "Ropa",
        "tops":                              "Ropa",
        "womens-shoes":                      "Ropa",
        "mens-shoes":                        "Ropa",
        "sports-accessories":                "Deportes",
        "vehicle":                           "Deportes",
        "home-decoration":                   "Hogar",
        "furniture":                         "Hogar",
        "kitchen-accessories":               "Hogar",
        "groceries":                         "Alimentos",
        "beauty":                            "Otros",
        "fragrances":                        "Otros",
        "skincare":                          "Otros",
        "sunglasses":                        "Electrónica",
    ]

    // MARK: - Public Entry Point

    func seedIfNeeded() async throws {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        try await seed()
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    func seed() async throws {
        try await clearAllCollections()

        let usuarios  = try await seedUsuarios()
        let productos = try await seedProductos()
        let clientes  = try await seedClientes()
        try await seedVentas(usuarios: usuarios, productos: productos, clientes: clientes)

        print("SeederService: Firestore initialized from dummyjson.")
    }

    // MARK: - Wipe

    private func clearAllCollections() async throws {
        for name in [Collections.ventas, Collections.clientes, Collections.productos, Collections.usuarios] {
            let snap = try await db.collection(name).getDocuments()
            for doc in snap.documents { try await doc.reference.delete() }
        }
    }

    // MARK: - Usuarios (hardcoded — Firebase Auth accounts)

    private func seedUsuarios() async throws -> [FBUsuario] {
        let data: [(name: String, email: String, pwd: String)] = [
            ("Ana García López",      "ana.garcia@tecsup.edu.pe",     "123456"),
            ("Carlos Mendoza Ríos",   "carlos.mendoza@tecsup.edu.pe", "123456"),
            ("Sofía Torres Castillo", "sofia.torres@tecsup.edu.pe",   "123456"),
        ]
        var usuarios: [FBUsuario] = []
        for item in data {
            let uid = try await getOrCreateAuthUser(email: item.email, password: item.pwd)
            let usuario = FBUsuario(
                id:             uid,
                nombreCompleto: item.name,
                correo:         item.email,
                fotoPerfil:     nil,
                fechaRegistro:  daysAgo(Int.random(in: 60...90))
            )
            try await FirestoreService.set(Collections.usuarios, id: uid, usuario)
            usuarios.append(usuario)
        }
        return usuarios
    }

    private func getOrCreateAuthUser(email: String, password: String) async throws -> String {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            return result.user.uid
        } catch {
            let nsError = error as NSError
            guard nsError.domain == AuthErrorDomain,
                  nsError.code == AuthErrorCode.emailAlreadyInUse.rawValue else { throw error }
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return result.user.uid
        }
    }

    // MARK: - Productos (from dummyjson)

    private func seedProductos() async throws -> [FBProducto] {
        let url = URL(string: "https://dummyjson.com/products?limit=20")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response  = try JSONDecoder().decode(DJProductsResponse.self, from: data)

        var productos: [FBProducto] = []
        for (index, item) in response.products.enumerated() {
            let ref       = db.collection(Collections.productos).document()
            let categoria = SeederService.categoryMap[item.category] ?? "Otros"
            let producto  = FBProducto(
                id:            ref.documentID,
                codigo:        String(format: "PROD-%03d", index + 1),
                nombre:        item.title,
                categoria:     categoria,
                precio:        (item.price * 100).rounded() / 100,
                stock:         item.stock,
                fotoProducto:  item.thumbnail,
                estado:        item.stock > 0 ? "Activo" : "Inactivo",
                fechaRegistro: daysAgo(Int.random(in: 15...75))
            )
            try ref.setData(from: producto)
            productos.append(producto)
        }
        return productos
    }

    // MARK: - Clientes (from dummyjson)

    private func seedClientes() async throws -> [FBCliente] {
        let url = URL(string: "https://dummyjson.com/users?limit=13")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response  = try JSONDecoder().decode(DJUsersResponse.self, from: data)

        var clientes: [FBCliente] = []
        for item in response.users {
            let ref = db.collection(Collections.clientes).document()
            // ponytail: deterministic fake DNI from user id — no collision within 13 users
            let dni = String(format: "%08d", (item.id * 7_654_321) % 100_000_000)
            let ubicacion = FBUbicacion(
                latitud:             item.address.coordinates.lat,
                longitud:            item.address.coordinates.lng,
                direccionReferencia: item.address.address,
                fechaRegistro:       daysAgo(Int.random(in: 5...45))
            )
            let cliente = FBCliente(
                id:            ref.documentID,
                dni:           dni,
                nombres:       item.firstName,
                apellidos:     item.lastName,
                telefono:      item.phone,
                correo:        item.email,
                direccion:     item.address.address,
                estado:        "Activo",
                fechaRegistro: daysAgo(Int.random(in: 5...45)),
                ubicacion:     ubicacion
            )
            try ref.setData(from: cliente)
            clientes.append(cliente)
        }
        return clientes
    }

    // MARK: - Ventas

    private func seedVentas(
        usuarios:  [FBUsuario],
        productos: [FBProducto],
        clientes:  [FBCliente]
    ) async throws {
        guard usuarios.count >= 2, clientes.count >= 5 else { return }

        let u0    = usuarios[0]
        let u1    = usuarios[1]
        let u2    = usuarios.count > 2 ? usuarios[2] : u1
        let users = [u0, u1, u2]

        var stockMap: [String: Int] = [:]
        for p in productos { if let id = p.id { stockMap[id] = p.stock } }

        let sellable = productos.filter { $0.isActive && $0.stock > 0 }
        guard sellable.count >= 3 else { return }

        let scenarios: [(Int, Int, Int, Int)] = [
            (0, 0,  1, 2), (1, 1,  1, 1), (2, 2,  2, 2),
            (3, 0,  3, 1), (4, 1,  3, 2), (5, 2,  4, 1),
            (6, 0,  5, 3), (7, 1,  5, 1), (8, 2,  6, 2),
            (0, 0,  7, 1), (1, 1,  8, 2), (2, 2,  9, 1),
            (9, 0, 10, 2), (10,1, 11, 1), (11,2, 12, 2),
            (3, 0, 13, 1), (4, 1, 14, 3), (5, 2, 15, 1),
            (6, 0, 17, 2), (7, 1, 18, 1), (12,2, 20, 2),
            (8, 0, 22, 1), (9, 1, 25, 2), (10,2, 28, 1),
            (0, 0, 30, 2),
        ]

        let batch = FirestoreService.batch()

        for (ci, ui, days, pickCount) in scenarios {
            guard ci < clientes.count else { continue }
            let cliente = clientes[ci]
            let usuario = users[ui % users.count]

            let pool = Array(sellable.shuffled().prefix(pickCount))
            var detalles: [FBDetalleVenta] = []
            var subtotal: Double = 0

            for producto in pool {
                guard let productID = producto.id else { continue }
                let availableStock = stockMap[productID] ?? 0
                let maxQty = min(2, availableStock)
                guard maxQty >= 1 else { continue }
                let qty       = Int.random(in: 1...maxQty)
                let lineTotal = producto.precio * Double(qty)
                subtotal += lineTotal

                detalles.append(FBDetalleVenta(
                    id:                UUID().uuidString,
                    productoId:        productID,
                    productoNombre:    producto.nombre,
                    productoCodigo:    producto.codigo,
                    productoCategoria: producto.categoria,
                    cantidad:          qty,
                    precioUnitario:    producto.precio,
                    subtotalLinea:     lineTotal
                ))
                stockMap[productID] = availableStock - qty
            }

            guard !detalles.isEmpty else { continue }

            let igv   = (subtotal * 0.18 * 100).rounded() / 100
            let total = subtotal + igv

            let ventaRef = db.collection(Collections.ventas).document()
            let venta = FBVenta(
                id:             ventaRef.documentID,
                fechaVenta:     daysAgo(days),
                subtotal:       (subtotal * 100).rounded() / 100,
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
            try batch.setData(from: venta, forDocument: ventaRef)
        }

        for (productID, newStock) in stockMap {
            let ref = db.collection(Collections.productos).document(productID)
            batch.updateData(["stock": newStock], forDocument: ref)
        }

        try await batch.commit()
    }

    // MARK: - Helpers

    private func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: Date()) ?? Date()
    }
}
