import UIKit

final class BienvenidaViewController: UIViewController {

    private let gradientLayer = CAGradientLayer()

    // MARK: - IBOutlets

    @IBOutlet weak var logoOuter: UIView!
    @IBOutlet weak var logoInner: UIView!
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var footerLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupGradient()
        setupLogoColors()
        applyThemeStyles()
        AppStyle.applyPrimary(to: loginButton, title: "Iniciar sesión")
        AppStyle.applySecondary(to: registerButton, title: "Crear cuenta")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    // MARK: - Setup

    private func setupGradient() {
        gradientLayer.colors = [
            UIColor.brandPrimary.withAlphaComponent(0.10).cgColor,
            UIColor.brandLight.withAlphaComponent(0.25).cgColor,
            UIColor.appBackground.cgColor
        ]
        gradientLayer.locations = [0, 0.5, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupLogoColors() {
        logoOuter.backgroundColor = UIColor.brandPrimary.withAlphaComponent(0.12)
        logoInner.backgroundColor = UIColor.brandPrimary.withAlphaComponent(0.08)
        logoImage.tintColor       = .brandPrimary
    }

    private func applyThemeStyles() {
        titleLabel.font          = AppFont.largeTitle()
        titleLabel.textColor     = .appTextPrimary
        titleLabel.textAlignment = .center

        subtitleLabel.font          = AppFont.body()
        subtitleLabel.textColor     = .appTextSecondary
        subtitleLabel.textAlignment = .center

        footerLabel.font          = AppFont.caption1()
        footerLabel.textColor     = .appTextTertiary
        footerLabel.textAlignment = .center
    }

}
