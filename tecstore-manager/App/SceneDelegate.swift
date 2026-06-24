import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // MARK: - Scene Connection

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Configure global UIKit appearance
        AppStyle.configureGlobalAppearance()

        // Build window — hasActiveSession is sync (Firebase Auth local cache)
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.rootViewController = makeRootViewController()
        window.makeKeyAndVisible()

        // Apply saved dark mode preference
        applyStoredAppearance()

        // Seed initial data on first launch (async — runs after window is visible)
        Task {
            try? await SeederService.shared.seedIfNeeded()
        }

        // Listen for logout events posted from SwiftUI screens
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLogout),
            name: .userDidLogout,
            object: nil
        )
    }

    // MARK: - Root View Controller

    /// Auth root replacement is a justified exception to the storyboard-segue rule.
    /// Login/logout swap the entire window root before the Main storyboard flow is active,
    /// so a manual root change is safer than trying to route them through segues.
    private func makeRootViewController() -> UIViewController {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        if AuthService.shared.hasActiveSession {
            return sb.instantiateViewController(withIdentifier: "MenuViewController")
        } else {
            let bienvenidaVC = sb.instantiateViewController(withIdentifier: "BienvenidaViewController")
            let nav = UINavigationController(rootViewController: bienvenidaVC)
            nav.setNavigationBarHidden(true, animated: false)
            return nav
        }
    }

    // MARK: - Transitions

    /// Replace root with MenuViewController (after login or register).
    /// Intentionally code-driven: the auth flow is outside the active storyboard hierarchy.
    func switchToMenu() {
        guard let window else { return }
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let menuVC = sb.instantiateViewController(withIdentifier: "MenuViewController")
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve) {
            window.rootViewController = menuVC
        }
    }

    /// Replace root with auth flow (after logout).
    /// Intentionally code-driven: the auth flow is outside the active storyboard hierarchy.
    func switchToAuth() {
        guard let window else { return }
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let bienvenidaVC = sb.instantiateViewController(withIdentifier: "BienvenidaViewController")
        let nav = UINavigationController(rootViewController: bienvenidaVC)
        nav.setNavigationBarHidden(true, animated: false)
        UIView.transition(with: window, duration: 0.35, options: .transitionCrossDissolve) {
            window.rootViewController = nav
        }
    }

    // MARK: - Dark Mode

    /// Apply and persist dark mode preference immediately
    func setDarkMode(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: UserDefaultsKeys.darkModeEnabled)
        window?.overrideUserInterfaceStyle = enabled ? .dark : .light
    }

    private func applyStoredAppearance() {
        let isDark = UserDefaults.standard.bool(forKey: UserDefaultsKeys.darkModeEnabled)
        window?.overrideUserInterfaceStyle = isDark ? .dark : .light
    }

    // MARK: - Notification Handlers

    @objc private func handleLogout() {
        switchToAuth()
    }

    // MARK: - Static Accessor

    /// Access SceneDelegate from anywhere in the app (useful from SwiftUI)
    static var shared: SceneDelegate? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.delegate as? SceneDelegate
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userDidLogout    = Notification.Name("userDidLogout")
    static let darkModeChanged  = Notification.Name("darkModeChanged")
    static let salesDataChanged = Notification.Name("salesDataChanged")
}

// MARK: - UserDefaults Keys

enum UserDefaultsKeys {
    static let darkModeEnabled  = "darkModeEnabled"
    static let activeUserID     = "activeUserID"   // kept for migration safety; no longer written
}
