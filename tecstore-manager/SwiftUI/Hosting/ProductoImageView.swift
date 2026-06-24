import SwiftUI
import UIKit

/// Loads a product image from a URL, app asset, or local Documents file.
/// Falls back to the category system icon when no image is available.
struct ProductoImageView: View {
    let path: String?
    let categoryIcon: String
    let categoryColor: Color

    var body: some View {
        Group {
            if let path, !path.isEmpty {
                if path.hasPrefix("http"), let url = URL(string: path) {
                    AsyncImage(url: url) { phase in
                        if let img = phase.image {
                            img.resizable().scaledToFill()
                        } else {
                            fallbackIcon
                        }
                    }
                } else if let uiImg = UIImage(named: path) ?? UIImage.fromDocuments(named: path) {
                    Image(uiImage: uiImg).resizable().scaledToFill()
                } else {
                    fallbackIcon
                }
            } else {
                fallbackIcon
            }
        }
    }

    private var fallbackIcon: some View {
        Image(systemName: categoryIcon)
            .foregroundColor(categoryColor)
    }
}
