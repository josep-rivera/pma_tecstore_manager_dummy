import SwiftUI

// ─────────────────────────────────────────────
// MARK: - StockBajoView
// ─────────────────────────────────────────────

struct StockBajoView: View {

    @ObservedObject var viewModel: StockBajoViewModel

    var body: some View {
        Group {
            if viewModel.productos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.appSuccess)
                    Text("Todos los productos tienen stock suficiente")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.productos) { p in
                    HStack(spacing: 12) {
                        Group {
                            ProductoImageView(
                                path:          p.productImagePath,
                                categoryIcon:  p.categoryEnum.icon,
                                categoryColor: Color(UIColor.colorForCategory(p.categoryValue))
                            )
                        }
                        .frame(width: 36, height: 36)
                        .background(Color(UIColor.colorForCategory(p.categoryValue)).opacity(0.12))
                        .cornerRadius(8)
                        .clipped()

                        VStack(alignment: .leading, spacing: 3) {
                            Text(p.productName).font(.subheadline.weight(.medium))
                            Text(p.productCode).font(.caption).foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            Text("\(p.stockInt) ud.")
                                .font(.subheadline.bold())
                                .foregroundColor(Color(p.stockInt.stockUIColor))
                            Text(p.stockInt.stockLabel)
                                .font(.caption2)
                                .foregroundColor(Color(p.stockInt.stockUIColor))
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(Color(UIColor.appSurface))
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Stock bajo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { viewModel.loadProductos() }
    }
}
