import Foundation
import FirebaseFirestore

// MARK: - FBUsuario  →  /usuarios/{uid}

struct FBUsuario: Codable, Identifiable {
    @DocumentID var id: String?
    var nombreCompleto: String
    var correo: String
    var fotoPerfil: String?
    var fechaRegistro: Date

    var fullName: String          { nombreCompleto }
    var email: String             { correo }
    var profileImagePath: String? { fotoPerfil }
    var registrationDate: Date    { fechaRegistro }
}

// MARK: - FBProducto  →  /productos/{autoId}

struct FBProducto: Codable, Identifiable {
    @DocumentID var id: String?
    var codigo: String
    var nombre: String
    var categoria: String
    var precio: Double
    var stock: Int
    var fotoProducto: String?
    var estado: String
    var fechaRegistro: Date

    var productCode: String       { codigo }
    var productName: String       { nombre }
    var categoryValue: String     { categoria }
    var priceDouble: Double       { precio }
    var stockInt: Int             { stock }
    var productImagePath: String? { fotoProducto }
    var statusValue: String       { estado }
    var registrationDate: Date    { fechaRegistro }
    var isActive: Bool            { estado == "Activo" }
    var hasStock: Bool            { stock > 0 }
    var categoryEnum: ProductCategory { ProductCategory(rawValue: categoria) ?? .otros }
}

// MARK: - FBUbicacion  (embedded map inside FBCliente — no own collection)

struct FBUbicacion: Codable, Hashable {
    var latitud: Double
    var longitud: Double
    var direccionReferencia: String?
    var fechaRegistro: Date

    var latitude: Double          { latitud }
    var longitude: Double         { longitud }
    var reference: String?        { direccionReferencia?.trimmed.isNotBlank == true ? direccionReferencia : nil }
    var registrationDate: Date    { fechaRegistro }
    var hasValidCoordinates: Bool { latitud != 0 || longitud != 0 }
}

// MARK: - FBCliente  →  /clientes/{autoId}

struct FBCliente: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var dni: String
    var nombres: String
    var apellidos: String
    var telefono: String?
    var correo: String?
    var direccion: String?
    var estado: String
    var fechaRegistro: Date
    var ubicacion: FBUbicacion?

    var dniValue: String          { dni }
    var firstNames: String        { nombres }
    var lastNames: String         { apellidos }
    var fullName: String          { "\(nombres) \(apellidos)".trimmed }
    var phoneNumber: String?      { telefono?.trimmed.isNotBlank == true ? telefono : nil }
    var emailValue: String?       { correo?.trimmed.isNotBlank == true ? correo : nil }
    var addressValue: String?     { direccion?.trimmed.isNotBlank == true ? direccion : nil }
    var statusValue: String       { estado }
    var registrationDate: Date    { fechaRegistro }
    var isActive: Bool            { estado == "Activo" }

    var latitude: Double           { ubicacion?.latitude  ?? 0 }
    var longitude: Double          { ubicacion?.longitude ?? 0 }
    var hasValidCoordinates: Bool  { ubicacion?.hasValidCoordinates ?? false }
    var locationReference: String? { ubicacion?.reference }
}

// MARK: - FBDetalleVenta  (embedded array inside FBVenta — no own collection)

struct FBDetalleVenta: Codable {
    var id: String
    var productoId: String
    var productoNombre: String
    var productoCodigo: String
    var productoCategoria: String
    var cantidad: Int
    var precioUnitario: Double
    var subtotalLinea: Double

    var quantityInt: Int        { cantidad }
    var unitPriceDouble: Double { precioUnitario }
    var lineTotalDouble: Double { subtotalLinea }
    var productName: String     { productoNombre }
    var productCode: String     { productoCodigo }
    var productCategory: String { productoCategoria }
}

// MARK: - FBVenta  →  /ventas/{autoId}

struct FBVenta: Codable, Identifiable {
    @DocumentID var id: String?
    var fechaVenta: Date
    var subtotal: Double
    var igv: Double
    var total: Double
    var estado: String
    var clienteId: String?
    var clienteNombre: String
    var clienteDNI: String
    var usuarioId: String?
    var vendedorNombre: String
    var detalles: [FBDetalleVenta]

    var saleDate: Date         { fechaVenta }
    var subtotalDouble: Double { subtotal }
    var totalDouble: Double    { total }
    var statusValue: String    { estado }
    var clientName: String     { clienteNombre.isNotBlank ? clienteNombre : "Sin cliente" }
    var sellerName: String     { vendedorNombre.isNotBlank ? vendedorNombre : "Sin vendedor" }
}
