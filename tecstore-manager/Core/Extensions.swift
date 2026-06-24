import UIKit
import SwiftUI
import CoreData

// ─────────────────────────────────────────────
// MARK: - String
// ─────────────────────────────────────────────

extension String {

    /// True if the string matches a valid email format.
    var isValidEmail: Bool {
        let regex = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: self)
    }

    /// True if the string is exactly 8 numeric digits (Peruvian DNI).
    var isValidDNI: Bool {
        let t = trimmed
        return t.count == 8 && t.allSatisfy(\.isNumber)
    }

    /// True if the string is a plausible phone number (7–15 digits, optional leading +).
    var isValidPhone: Bool {
        let regex = #"^\+?[0-9]{7,15}$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: trimmed)
    }

    /// String without leading/trailing whitespace or newlines.
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// True when the string is empty or contains only whitespace.
    /// Named `isBlank` to avoid shadowing the stdlib `String.isEmpty`.
    var isBlank: Bool { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// True when the string contains at least one non-whitespace character.
    var isNotBlank: Bool { !isBlank }
}

// ─────────────────────────────────────────────
// MARK: - UIView
// ─────────────────────────────────────────────

extension UIView {

    /// Add multiple subviews at once; sets translatesAutoresizingMaskIntoConstraints = false.
    func addSubviews(_ views: UIView...) {
        views.forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
    }

    /// Pin all edges to a given view with optional individual insets.
    func pinEdges(
        to view: UIView,
        top:      CGFloat = 0,
        leading:  CGFloat = 0,
        trailing: CGFloat = 0,
        bottom:   CGFloat = 0
    ) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor,      constant:  top),
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: leading),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -trailing),
            bottomAnchor.constraint(equalTo: view.bottomAnchor,  constant: -bottom)
        ])
    }

    /// Pin to the safe area of the given view controller.
    func pinToSafeArea(
        of vc: UIViewController,
        top:      CGFloat = AppLayout.padding,
        leading:  CGFloat = AppLayout.padding,
        trailing: CGFloat = AppLayout.padding,
        bottom:   CGFloat = AppLayout.padding
    ) {
        translatesAutoresizingMaskIntoConstraints = false
        let g = vc.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: g.topAnchor,       constant:  top),
            leadingAnchor.constraint(equalTo: g.leadingAnchor,  constant: leading),
            trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -trailing),
            bottomAnchor.constraint(equalTo: g.bottomAnchor,   constant: -bottom)
        ])
    }

    /// Center in the given view.
    func centerIn(_ view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    /// Set explicit size constraints.
    @discardableResult
    func constrainSize(width: CGFloat? = nil, height: CGFloat? = nil) -> [NSLayoutConstraint] {
        translatesAutoresizingMaskIntoConstraints = false
        var constraints: [NSLayoutConstraint] = []
        if let w = width  { constraints.append(widthAnchor.constraint(equalToConstant: w)) }
        if let h = height { constraints.append(heightAnchor.constraint(equalToConstant: h)) }
        NSLayoutConstraint.activate(constraints)
        return constraints
    }

    /// Apply a subtle drop shadow.
    func applyShadow(
        color:   UIColor = .black,
        opacity: Float   = 0.08,
        radius:  CGFloat = 6,
        offset:  CGSize  = CGSize(width: 0, height: 2)
    ) {
        layer.shadowColor   = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius  = radius
        layer.shadowOffset  = offset
        layer.masksToBounds = false
    }

    /// Round specific corners.
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path  = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners,
                                  cornerRadii: CGSize(width: radius, height: radius))
        let mask  = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

// ─────────────────────────────────────────────
// MARK: - UIViewController
// ─────────────────────────────────────────────

extension UIViewController {

    /// Present a simple informational alert.
    func showAlert(
        title:       String,
        message:     String,
        buttonTitle: String  = "OK",
        completion:  (() -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonTitle, style: .default) { _ in completion?() })
        present(alert, animated: true)
    }

    /// Present a confirmation alert with a destructive action.
    func showDestructiveConfirmation(
        title:            String,
        message:          String,
        destructiveTitle: String   = "Eliminar",
        onConfirm:        @escaping () -> Void
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancelar",       style: .cancel))
        alert.addAction(UIAlertAction(title: destructiveTitle, style: .destructive) { _ in onConfirm() })
        present(alert, animated: true)
    }

    /// Present an action sheet to choose between Camera and Gallery.
    /// Camera option is hidden automatically when not available (e.g., Simulator).
    func showImageSourcePicker(
        onCamera:  @escaping () -> Void,
        onGallery: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title:   "Seleccionar imagen",
            message: nil,
            preferredStyle: .actionSheet
        )
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Cámara",  style: .default) { _ in onCamera() })
        }
        alert.addAction(UIAlertAction(title: "Galería",     style: .default) { _ in onGallery() })
        alert.addAction(UIAlertAction(title: "Cancelar",    style: .cancel))

        // iPad support
        if let pop = alert.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        present(alert, animated: true)
    }

    /// Hide the keyboard by resigning first responder.
    func dismissKeyboard() {
        view.endEditing(true)
    }

    /// Convenient access to the SceneDelegate for navigation transitions.
    var sceneDelegate: SceneDelegate? {
        view.window?.windowScene?.delegate as? SceneDelegate
    }
}

// ─────────────────────────────────────────────
// MARK: - Date
// ─────────────────────────────────────────────

extension Date {

    private static let peruLocale = Locale(identifier: "es_PE")

    func formatted(pattern: String) -> String {
        let f        = DateFormatter()
        f.dateFormat = pattern
        f.locale     = Date.peruLocale
        return f.string(from: self)
    }

    /// "05/12/2025"
    var displayDate: String       { formatted(pattern: "dd/MM/yyyy") }
    /// "05/12/2025 14:30"
    var displayDateTime: String   { formatted(pattern: "dd/MM/yyyy HH:mm") }
    /// "diciembre 2025"
    var displayMonth: String      { formatted(pattern: "MMMM yyyy") }
    /// "05 dic. 2025"
    var displayShortDate: String  { formatted(pattern: "dd MMM yyyy") }
    /// "14:30"
    var displayTime: String       { formatted(pattern: "HH:mm") }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var startOfMonth: Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: comps) ?? self
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    var isToday: Bool { Calendar.current.isDateInToday(self) }
}

// ─────────────────────────────────────────────
// MARK: - Decimal & Double (Currency)
// ─────────────────────────────────────────────

private let currencyFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle             = .decimal
    f.minimumFractionDigits   = 2
    f.maximumFractionDigits   = 2
    f.locale                  = Locale(identifier: "es_PE")
    return f
}()

extension Double {
    /// "S/ 1,234.50"
    var asCurrency: String {
        let formatted = currencyFormatter.string(from: NSNumber(value: self)) ?? "0.00"
        return "S/ \(formatted)"
    }
}

extension Decimal {
    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
    var asCurrency:  String { doubleValue.asCurrency }
    var intValue:    Int    { NSDecimalNumber(decimal: self).intValue }

    static func from(_ double: Double) -> Decimal { Decimal(double) }

    /// Rounded to 2 fractional digits (currency cents). Use for stored money
    /// values so the persisted amount matches what is displayed.
    var roundedToCents: Decimal {
        var value  = self
        var result = Decimal()
        NSDecimalRound(&result, &value, 2, .plain)
        return result
    }
}

// ─────────────────────────────────────────────
// MARK: - Int (Stock helpers)
// ─────────────────────────────────────────────

extension Int {
    /// Color-codes stock level: 0 → error, 1–lowStockThreshold → warning, lowStockThreshold+1+ → success.
    var stockUIColor: UIColor {
        if self == 0 { return .appError }
        if self <= AppConstants.lowStockThreshold { return .appWarning }
        return .appSuccess
    }

    var stockColor: Color { Color(stockUIColor) }

    /// Text label for the stock status.
    var stockLabel: String {
        if self == 0 { return "Sin stock" }
        if self <= AppConstants.lowStockThreshold { return "Stock bajo" }
        return "En stock"
    }
}

// ─────────────────────────────────────────────
// MARK: - NSManagedObjectContext
// ─────────────────────────────────────────────

extension NSManagedObjectContext {
    /// Save only if there are pending changes; logs errors without crashing.
    func saveIfNeeded() {
        guard hasChanges else { return }
        do {
            try save()
        } catch {
            print("CoreData save error: \(error.localizedDescription)")
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - UIImage (Local File Storage)
// ─────────────────────────────────────────────

extension UIImage {

    /// Save JPEG to the Documents directory. Returns the file name on success.
    @discardableResult
    func saveToDocuments(named fileName: String, quality: CGFloat = 0.80) -> String? {
        guard let data = jpegData(compressionQuality: quality) else { return nil }
        let url = FileManager.documentsDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: .atomic)
            return url.lastPathComponent
        } catch {
            print("Image save error: \(error.localizedDescription)")
            return nil
        }
    }

    /// Load an image from the Documents directory by file name.
    static func fromDocuments(named fileName: String) -> UIImage? {
        let url = FileManager.documentsDirectory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: url.path)
    }

    /// Resize to fit within maxDimension while keeping aspect ratio.
    func resized(maxDimension: CGFloat = 800) -> UIImage {
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1)
        guard scale < 1 else { return self }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

// ─────────────────────────────────────────────
// MARK: - FileManager
// ─────────────────────────────────────────────

extension FileManager {
    static var documentsDirectory: URL {
        `default`.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

// ─────────────────────────────────────────────
// MARK: - UUID
// ─────────────────────────────────────────────

extension UUID {
    /// Convenience string representation without hyphens.
    var compact: String { uuidString.replacingOccurrences(of: "-", with: "") }
}

// ─────────────────────────────────────────────
// MARK: - UIImageView (Remote + Local Loading)
// ─────────────────────────────────────────────

extension UIImageView {

    /// Load from an Assets.xcassets name or a Documents filename.
    /// Both sources are synchronous, so this is safe to call from cell reuse.
    func setImage(from path: String?, placeholder: UIImage? = nil) {
        image = placeholder
        guard let path, !path.isEmpty else { return }
        if path.hasPrefix("http") {
            guard let url = URL(string: path) else { return }
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data, let loaded = UIImage(data: data) else { return }
                DispatchQueue.main.async { self?.image = loaded }
            }.resume()
        } else if let asset = UIImage(named: path) {
            image = asset
        } else {
            image = UIImage.fromDocuments(named: path) ?? placeholder
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - SwiftUI Helpers
// ─────────────────────────────────────────────

extension View {
    /// Dismiss the keyboard from a SwiftUI view.
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    /// Apply a consistent card background style in SwiftUI.
    func cardStyle(cornerRadius: CGFloat = AppLayout.cornerRadius) -> some View {
        self
            .padding(AppLayout.padding)
            .background(Color(UIColor.appSurface))
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 2)
    }
}
