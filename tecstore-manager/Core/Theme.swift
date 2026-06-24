import UIKit
import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Brand & Semantic Colors (UIKit)
// ─────────────────────────────────────────────

extension UIColor {

    // Semantic — automatically adapt to light/dark mode
    static let appBackground   = UIColor.systemBackground
    static let appSurface      = UIColor.secondarySystemBackground
    static let appGrouped      = UIColor.systemGroupedBackground
    static let appSeparator    = UIColor.separator

    static let appTextPrimary   = UIColor.label
    static let appTextSecondary = UIColor.secondaryLabel
    static let appTextTertiary  = UIColor.tertiaryLabel
    static let appPlaceholder   = UIColor.placeholderText

    // Category badge colors
    static let catElectronica  = UIColor.systemIndigo
    static let catRopa         = UIColor.systemPink
    static let catAlimentos    = UIColor.systemGreen
    static let catLimpieza     = UIColor.systemCyan
    static let catHogar        = UIColor.systemBrown
    static let catTecnologia   = UIColor.systemBlue
    static let catDeportes     = UIColor.systemOrange
    static let catOtros        = UIColor.systemGray

    /// Returns the accent color for a given product category string
    static func colorForCategory(_ category: String) -> UIColor {
        switch category {
        case "Electrónica":  return .catElectronica
        case "Ropa":         return .catRopa
        case "Alimentos":    return .catAlimentos
        case "Limpieza":     return .catLimpieza
        case "Hogar":        return .catHogar
        case "Tecnología":   return .catTecnologia
        case "Deportes":     return .catDeportes
        default:             return .catOtros
        }
    }

    // MARK: Hex Initializer

    convenience init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)
        self.init(
            red:   CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >>  8) / 255.0,
            blue:  CGFloat( rgb & 0x0000FF        ) / 255.0,
            alpha: 1.0
        )
    }
}

// ─────────────────────────────────────────────
// MARK: - Brand & Semantic Colors (SwiftUI)
// ─────────────────────────────────────────────

extension Color {
    static func forCategory(_ category: String) -> Color {
        Color(UIColor.colorForCategory(category))
    }
}

// ─────────────────────────────────────────────
// MARK: - Product Categories
// ─────────────────────────────────────────────

enum ProductCategory: String, CaseIterable {
    case electronica  = "Electrónica"
    case ropa         = "Ropa"
    case alimentos    = "Alimentos"
    case limpieza     = "Limpieza"
    case hogar        = "Hogar"
    case tecnologia   = "Tecnología"
    case deportes     = "Deportes"
    case otros        = "Otros"

    var color: UIColor { UIColor.colorForCategory(rawValue) }
    var icon: String {
        switch self {
        case .electronica: return "bolt.fill"
        case .ropa:        return "tshirt.fill"
        case .alimentos:   return "fork.knife"
        case .limpieza:    return "sparkles"
        case .hogar:       return "house.fill"
        case .tecnologia:  return "laptopcomputer"
        case .deportes:    return "figure.run"
        case .otros:       return "square.grid.2x2.fill"
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Typography
// ─────────────────────────────────────────────

enum AppFont {
    static func largeTitle()  -> UIFont { .systemFont(ofSize: 34, weight: .bold) }
    static func title1()      -> UIFont { .systemFont(ofSize: 28, weight: .bold) }
    static func title2()      -> UIFont { .systemFont(ofSize: 22, weight: .bold) }
    static func title3()      -> UIFont { .systemFont(ofSize: 20, weight: .semibold) }
    static func headline()    -> UIFont { .systemFont(ofSize: 17, weight: .semibold) }
    static func body()        -> UIFont { .systemFont(ofSize: 17, weight: .regular) }
    static func callout()     -> UIFont { .systemFont(ofSize: 16, weight: .regular) }
    static func subheadline() -> UIFont { .systemFont(ofSize: 15, weight: .regular) }
    static func footnote()    -> UIFont { .systemFont(ofSize: 13, weight: .regular) }
    static func caption1()    -> UIFont { .systemFont(ofSize: 12, weight: .regular) }
    static func caption2()    -> UIFont { .systemFont(ofSize: 11, weight: .regular) }
    static func mono()        -> UIFont { .monospacedSystemFont(ofSize: 15, weight: .regular) }
}

// ─────────────────────────────────────────────
// MARK: - Layout Constants
// ─────────────────────────────────────────────

enum AppLayout {
    static let padding:           CGFloat = 16
    static let paddingLarge:      CGFloat = 24
    static let paddingSmall:      CGFloat = 8
    static let paddingXSmall:     CGFloat = 4
    static let cornerRadius:      CGFloat = 12
    static let cornerRadiusSm:    CGFloat = 8
    static let cornerRadiusLg:    CGFloat = 20
    static let buttonHeight:      CGFloat = 50
    static let textFieldHeight:   CGFloat = 50
    static let cellHeight:        CGFloat = 72
    static let iconSize:          CGFloat = 24
    static let iconSizeLg:        CGFloat = 48
    static let photoThumb:        CGFloat = 80
    static let photoLarge:        CGFloat = 160
    static let avatarSize:        CGFloat = 72
    static let separatorHeight:   CGFloat = 0.5
}

// ─────────────────────────────────────────────
// MARK: - Business Constants
// ─────────────────────────────────────────────

// Explicitly nonisolated so these pure value constants can be referenced from
// any concurrency context (e.g. default-parameter values in non-MainActor services).
nonisolated enum AppConstants {
    static let lowStockThreshold:       Int = 5
    static let profileImageMaxDimension: CGFloat = 600
    static let passwordMinLength:        Int = 6
    static let topProductosLimit:        Int = 3
    static let salesTrendWindowDays:     Int = 14
}

// ─────────────────────────────────────────────
// MARK: - AppStyle — UIKit Styling Helpers
// ─────────────────────────────────────────────

enum AppStyle {

    // MARK: Global Appearance (called once from SceneDelegate)

    static func configureGlobalAppearance() {
        // Navigation Bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = .appBackground
        navAppearance.shadowColor = .appSeparator
        navAppearance.titleTextAttributes = [
            .font:            AppFont.headline(),
            .foregroundColor: UIColor.appTextPrimary
        ]
        navAppearance.largeTitleTextAttributes = [
            .font:            AppFont.title1(),
            .foregroundColor: UIColor.appTextPrimary
        ]
        UINavigationBar.appearance().standardAppearance          = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance        = navAppearance
        UINavigationBar.appearance().compactAppearance           = navAppearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor            = .brandPrimary

        // Tab Bar
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = .appBackground

        let normal   = tabAppearance.stackedLayoutAppearance.normal
        let selected = tabAppearance.stackedLayoutAppearance.selected

        normal.titleTextAttributes   = [.foregroundColor: UIColor.appTextSecondary, .font: AppFont.caption2()]
        selected.titleTextAttributes = [.foregroundColor: UIColor.brandPrimary,     .font: AppFont.caption2()]
        selected.iconColor           = .brandPrimary

        UITabBar.appearance().standardAppearance  = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().tintColor            = .brandPrimary

        // UITextField cursor
        UITextField.appearance().tintColor = .brandPrimary
        // UITextView cursor
        UITextView.appearance().tintColor  = .brandPrimary
    }

    // ─────────────────────────────────────────
    // MARK: Buttons
    // ─────────────────────────────────────────

    static func applyPrimary(to button: UIButton, title: String, icon: String? = nil) {
        var config = UIButton.Configuration.filled()
        config.title              = title
        config.baseBackgroundColor = .brandPrimary
        config.baseForegroundColor = .white
        config.cornerStyle        = .medium
        config.contentInsets      = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
        if let icon {
            config.image              = UIImage(systemName: icon)
            config.imagePlacement     = .leading
            config.imagePadding       = 8
        }
        config.titleTextAttributesTransformer = textTransformer(AppFont.headline())
        button.configuration = config
    }

    static func applySecondary(to button: UIButton, title: String, icon: String? = nil) {
        var config = UIButton.Configuration.bordered()
        config.title              = title
        config.baseBackgroundColor = .clear
        config.baseForegroundColor = .brandPrimary
        config.cornerStyle        = .medium
        config.contentInsets      = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
        config.background.strokeColor = .brandPrimary
        config.background.strokeWidth = 1.5
        if let icon {
            config.image          = UIImage(systemName: icon)
            config.imagePlacement = .leading
            config.imagePadding   = 8
        }
        config.titleTextAttributesTransformer = textTransformer(AppFont.headline())
        button.configuration = config
    }

    static func applyDestructive(to button: UIButton, title: String) {
        var config = UIButton.Configuration.filled()
        config.title               = title
        config.baseBackgroundColor = .appError
        config.baseForegroundColor = .white
        config.cornerStyle         = .medium
        config.contentInsets       = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
        config.titleTextAttributesTransformer = textTransformer(AppFont.headline())
        button.configuration = config
    }

    static func applyText(to button: UIButton, title: String, color: UIColor = .brandPrimary) {
        var config = UIButton.Configuration.plain()
        config.title               = title
        config.baseForegroundColor = color
        config.contentInsets       = .zero
        config.titleTextAttributesTransformer = textTransformer(AppFont.subheadline())
        button.configuration = config
    }

    private static func textTransformer(_ font: UIFont) -> UIConfigurationTextAttributesTransformer {
        UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = font
            return a
        }
    }

    // ─────────────────────────────────────────
    // MARK: Text Fields
    // ─────────────────────────────────────────

    /// Applies visual styling. Constraints are set by the ViewController.
    static func style(
        textField field: UITextField,
        placeholder: String,
        icon: String? = nil,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        returnKey: UIReturnKeyType = .next
    ) {
        field.placeholder            = placeholder
        field.font                   = AppFont.body()
        field.textColor              = .appTextPrimary
        field.isSecureTextEntry      = isSecure
        field.autocapitalizationType = .none
        field.autocorrectionType     = .no
        field.spellCheckingType      = .no
        field.keyboardType           = keyboardType
        field.returnKeyType          = returnKey
        field.layer.cornerRadius     = AppLayout.cornerRadiusSm
        field.layer.borderWidth      = 1.0
        field.layer.borderColor      = UIColor.appSeparator.cgColor
        field.backgroundColor        = .appSurface
        field.clipsToBounds          = true

        // Left padding / icon
        if let iconName = icon {
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: AppLayout.textFieldHeight))
            let img = UIImageView(image: UIImage(systemName: iconName))
            img.tintColor    = .appTextSecondary
            img.contentMode  = .scaleAspectFit
            img.frame        = CGRect(x: 10, y: 13, width: 22, height: 22)
            container.addSubview(img)
            field.leftView   = container
        } else {
            field.leftView   = UIView(frame: CGRect(x: 0, y: 0, width: AppLayout.padding, height: AppLayout.textFieldHeight))
        }
        field.leftViewMode = .always

        // Right: eye toggle for secure fields, clear button otherwise
        if isSecure {
            field.clearButtonMode = .never
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 52, height: AppLayout.textFieldHeight))
            let btn = UIButton(type: .custom)
            btn.frame     = CGRect(x: 0, y: 0, width: 44, height: AppLayout.textFieldHeight)
            btn.tintColor = .appTextSecondary
            btn.setImage(UIImage(systemName: "eye"),       for: .normal)
            btn.setImage(UIImage(systemName: "eye.slash"), for: .selected)
            btn.addAction(UIAction { [weak field, weak btn] _ in
                let saved = field?.text
                field?.isSecureTextEntry.toggle()
                field?.text = saved  // UIKit clears text when toggling isSecureTextEntry back to true
                btn?.isSelected = !(field?.isSecureTextEntry ?? true)
            }, for: .touchUpInside)
            container.addSubview(btn)
            field.rightView     = container
            field.rightViewMode = .always
        } else {
            field.clearButtonMode = .whileEditing
        }
    }

    /// Highlight field border on validation error
    static func markFieldError(_ field: UITextField, hasError: Bool) {
        field.layer.borderColor = hasError
            ? UIColor.appError.cgColor
            : UIColor.appSeparator.cgColor
        field.layer.borderWidth = hasError ? 1.5 : 1.0
    }

    // ─────────────────────────────────────────
    // MARK: Labels
    // ─────────────────────────────────────────

    static func makeErrorLabel() -> UILabel {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font          = AppFont.caption1()
        l.textColor     = .appError
        l.numberOfLines = 0
        l.isHidden      = true
        return l
    }

    static func makeFieldLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text      = text
        l.font      = AppFont.subheadline()
        l.textColor = .appTextSecondary
        return l
    }

    static func makeTitleLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text          = text
        l.font          = AppFont.title2()
        l.textColor     = .appTextPrimary
        l.numberOfLines = 0
        return l
    }

    // ─────────────────────────────────────────
    // MARK: Cards / Containers
    // ─────────────────────────────────────────

    static func applyCardStyle(to view: UIView, cornerRadius: CGFloat = AppLayout.cornerRadius) {
        view.backgroundColor    = .appSurface
        view.layer.cornerRadius = cornerRadius
        view.layer.borderWidth  = 0.5
        view.layer.borderColor  = UIColor.appSeparator.cgColor
        view.applyShadow()
    }

    // ─────────────────────────────────────────
    // MARK: Badge / Chip
    // ─────────────────────────────────────────

    static func makeBadgeLabel(text: String, color: UIColor = .brandPrimary) -> UILabel {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text                        = text
        l.font                        = AppFont.caption1()
        l.textColor                   = .white
        l.backgroundColor             = color
        l.textAlignment               = .center
        l.layer.cornerRadius          = 6
        l.clipsToBounds               = true
        l.layer.masksToBounds         = true
        // Intrinsic padding via content insets isn't directly available on UILabel;
        // callers should add ≥8pt horizontal padding via constraints.
        return l
    }

    // ─────────────────────────────────────────
    // MARK: Stack Views
    // ─────────────────────────────────────────

    static func makeVStack(spacing: CGFloat = AppLayout.padding) -> UIStackView {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis         = .vertical
        sv.spacing      = spacing
        sv.alignment    = .fill
        sv.distribution = .fill
        return sv
    }

    static func makeHStack(spacing: CGFloat = AppLayout.paddingSmall,
                           alignment: UIStackView.Alignment = .center) -> UIStackView {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis         = .horizontal
        sv.spacing      = spacing
        sv.alignment    = alignment
        sv.distribution = .fill
        return sv
    }

    // ─────────────────────────────────────────
    // MARK: Divider
    // ─────────────────────────────────────────

    static func makeDivider() -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .appSeparator
        v.heightAnchor.constraint(equalToConstant: AppLayout.separatorHeight).isActive = true
        return v
    }
}
