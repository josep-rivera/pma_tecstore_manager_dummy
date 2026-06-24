import SwiftUI
import Combine

// ─────────────────────────────────────────────
// MARK: - DetalleVentaViewModel
// Read-only formatter for the sale detail screen.
// ─────────────────────────────────────────────

@MainActor
final class DetalleVentaViewModel: ObservableObject {

    let venta: FBVenta

    init(venta: FBVenta) {
        self.venta = venta
    }

    var igv: Double {
        venta.totalDouble - venta.subtotalDouble
    }
}
