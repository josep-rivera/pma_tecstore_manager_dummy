import UIKit

final class DetalleProductoViewController: UIViewController {

    // MARK: - Data
    var producto: FBProducto?

    // MARK: - IBOutlets
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var nombreLabel:    UILabel!
    // These outlets are intentionally optional: the storyboard may not wire
    // every placeholder label, and force-unwrapping would crash on rotation
    // or view lifecycle transitions if an outlet is nil.
    @IBOutlet weak var precioLabel:    UILabel?
    @IBOutlet weak var stockBadge:     UILabel?
    @IBOutlet weak var estadoBadge:    UILabel?

    // MARK: - IBOutlets (storyboard-placed, styled in code)
    @IBOutlet weak var infoCard: UIView!
    @IBOutlet weak var div1: UIView!
    @IBOutlet weak var div2: UIView!
    @IBOutlet weak var div3: UIView!
    @IBOutlet weak var div4: UIView!

    // MARK: - UI
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var stockRow: InfoRow!
    @IBOutlet weak var estadoRow: InfoRow!
    @IBOutlet weak var codigoRow: InfoRow!
    @IBOutlet weak var categoriaRow: InfoRow!
    @IBOutlet weak var fechaRow: InfoRow!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupIBOutletStyling()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        populate()
        guard let producto else { return }
        Task { if let updated = try? await ProductoService.shared.fetch(byID: producto.id ?? "") { await MainActor.run { self.producto = updated; self.populate() } } }
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .appBackground
        title = "Detalle del producto"
        navigationItem.largeTitleDisplayMode = .never
    }

    private func setupIBOutletStyling() {
        photoImageView.contentMode     = .scaleAspectFit
        photoImageView.clipsToBounds   = true
        photoImageView.backgroundColor = .appSurface

        nombreLabel.font          = .systemFont(ofSize: 20, weight: .bold)
        nombreLabel.textColor     = .appTextPrimary
        nombreLabel.numberOfLines = 2

        // precioLabel, stockBadge, estadoBadge are now unused as IBOutlets for display —
        // they're hidden; InfoRows in the storyboard card handle display.
        // Use optional chaining so a disconnected outlet cannot crash on rotation.
        precioLabel?.isHidden  = true
        stockBadge?.isHidden   = true
        estadoBadge?.isHidden  = true

        codeLabel.font      = .systemFont(ofSize: 13, weight: .regular)
        codeLabel.textColor = .appTextSecondary

        infoCard.backgroundColor    = .appSurface
        infoCard.layer.cornerRadius = AppLayout.cornerRadius
        infoCard.layer.cornerCurve  = .continuous

        for div in ([div1, div2, div3, div4] as [UIView]) {
            div.backgroundColor = .appSeparator
        }
    }

    // MARK: - Populate

    private func resetUI() {
        photoImageView.image = nil
        photoImageView.contentMode = .scaleAspectFit

        nombreLabel.text = ""
        codeLabel.text   = ""

        stockRow.configure(icon: "shippingbox", title: "Stock", value: "-")
        estadoRow.configure(icon: "xmark.circle", title: "Estado", value: "-")
        codigoRow.configure(icon: "barcode", title: "Código", value: "-")
        categoriaRow.configure(icon: "tag", title: "Categoría", value: "-")
        fechaRow.configure(icon: "calendar", title: "Registrado", value: "-")

        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    private func populate() {
        guard let p = producto else {
            resetUI()
            return
        }

        navigationItem.rightBarButtonItem?.isEnabled = true

        let placeholder = UIImage(systemName: "shippingbox")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 40, weight: .light))
            .withRenderingMode(.alwaysTemplate)
        photoImageView.setImage(from: p.productImagePath, placeholder: placeholder)
        photoImageView.tintColor = p.productImagePath == nil ? .appTextTertiary : nil
        if p.productImagePath != nil { photoImageView.contentMode = .scaleAspectFill }

        nombreLabel.text = p.productName
        codeLabel.text   = "\(p.productCode)  ·  \(p.categoryValue)"

        let stockInt = p.stockInt
        stockRow.configure(
            icon:  "shippingbox",
            title: "Stock",
            value: "\(stockInt) \(stockInt == 1 ? "unidad" : "unidades")",
            valueColor: stockInt.stockUIColor
        )
        estadoRow.configure(
            icon:  p.isActive ? "checkmark.circle" : "xmark.circle",
            title: "Estado",
            value: p.statusValue,
            valueColor: p.isActive ? .appSuccess : .appTextSecondary
        )
        codigoRow.configure(icon: "barcode", title: "Código", value: p.productCode)
        categoriaRow.configure(icon: "tag", title: "Categoría", value: p.categoryValue)
        fechaRow.configure(icon: "calendar", title: "Registrado", value: p.registrationDate.displayDate)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let producto else { return }
        if let dest = segue.destination as? FormularioProductoViewController {
            dest.producto = producto
            dest.onSave   = { }
        }
    }
}

// MARK: - InfoRow

final class InfoRow: UIView {

    private let iconView  = UIImageView()
    private let titleLbl  = UILabel()
    private let valueLbl  = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupRow()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupRow()
    }

    private func setupRow() {
        iconView.translatesAutoresizingMaskIntoConstraints  = false
        titleLbl.translatesAutoresizingMaskIntoConstraints  = false
        valueLbl.translatesAutoresizingMaskIntoConstraints  = false

        iconView.tintColor      = .appTextTertiary
        iconView.contentMode    = .scaleAspectFit

        titleLbl.font           = .systemFont(ofSize: 15, weight: .regular)
        titleLbl.textColor      = .appTextSecondary

        valueLbl.font           = .systemFont(ofSize: 15, weight: .medium)
        valueLbl.textColor      = .appTextPrimary
        valueLbl.textAlignment  = .right
        valueLbl.numberOfLines  = 1
        valueLbl.adjustsFontSizeToFitWidth = true
        valueLbl.minimumScaleFactor = 0.8

        addSubview(iconView); addSubview(titleLbl); addSubview(valueLbl)

        let p: CGFloat = 16
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            titleLbl.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            titleLbl.centerYAnchor.constraint(equalTo: centerYAnchor),

            valueLbl.leadingAnchor.constraint(equalTo: titleLbl.trailingAnchor, constant: 8),
            valueLbl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            valueLbl.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    func configure(icon: String, title: String, value: String, valueColor: UIColor = .appTextPrimary) {
        iconView.image  = UIImage(systemName: icon)?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 14, weight: .regular))
        titleLbl.text   = title
        valueLbl.text   = value
        valueLbl.textColor = valueColor
    }
}
