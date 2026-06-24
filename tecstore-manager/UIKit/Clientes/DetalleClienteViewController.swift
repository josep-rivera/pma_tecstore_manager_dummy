import UIKit
import MapKit

final class DetalleClienteViewController: UIViewController {

    // MARK: - Data
    var cliente: FBCliente?

    // MARK: - IBOutlets (storyboard-placed, styled in code)
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusBadge: UILabel!
    @IBOutlet weak var dniLabel: UILabel!
    @IBOutlet weak var telefonoLabel: UILabel!
    @IBOutlet weak var correoLabel: UILabel!
    @IBOutlet weak var direccionLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!

    // Storyboard-placed separator views and placeholder label
    @IBOutlet weak var contactDiv1: UIView!
    @IBOutlet weak var contactDiv2: UIView!
    @IBOutlet weak var contactDiv3: UIView!
    @IBOutlet weak var contactDiv4: UIView!
    @IBOutlet weak var noLocationLabel: UILabel!

    // MARK: - UI
    @IBOutlet weak var avatarView: UIView!
    @IBOutlet weak var avatarLetter: UILabel!

    @IBOutlet weak var contactCard: UIView!
    @IBOutlet weak var fechaLabel: UILabel!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupIBOutletStyling()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        populate()
        guard let cliente else { return }
        Task { if let updated = try? await ClienteService.shared.fetch(byID: cliente.id ?? "") { await MainActor.run { self.cliente = updated; self.populate() } } }
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .appBackground
        title = "Detalle del cliente"
        navigationItem.largeTitleDisplayMode = .never
    }

    /// Apply styling to IBOutlet views without adding or constraining them (storyboard owns layout).
    /// Every access uses optional chaining so a nil outlet (e.g. after a rotation-induced
    /// view lifecycle transition) cannot crash the app.
    private func setupIBOutletStyling() {
        nameLabel?.font          = AppFont.title2()
        nameLabel?.textColor     = .appTextPrimary
        nameLabel?.textAlignment = .center
        nameLabel?.numberOfLines = 0

        statusBadge?.font               = AppFont.caption1()
        statusBadge?.textColor          = .white
        statusBadge?.textAlignment      = .center
        statusBadge?.layer.cornerRadius = 12
        statusBadge?.clipsToBounds      = true

        avatarView?.backgroundColor    = .brandLight
        avatarView?.layer.cornerRadius = 48

        avatarLetter?.font          = AppFont.title1()
        avatarLetter?.textColor     = .brandPrimary
        avatarLetter?.textAlignment = .center

        contactCard?.backgroundColor    = .appSurface
        contactCard?.layer.cornerRadius = AppLayout.cornerRadius
        contactCard?.layer.cornerCurve  = .continuous

        fechaLabel?.font      = AppFont.footnote()
        fechaLabel?.textColor = .appTextTertiary

        for div in ([contactDiv1, contactDiv2, contactDiv3, contactDiv4] as [UIView?]) {
            div?.backgroundColor = .appSeparator
        }

        for lbl in ([dniLabel, telefonoLabel, correoLabel, direccionLabel] as [UILabel?]) {
            lbl?.font          = AppFont.body()
            lbl?.textColor     = .appTextSecondary
            lbl?.numberOfLines = 0
        }

        noLocationLabel?.font      = AppFont.footnote()
        noLocationLabel?.textColor = .appTextTertiary

        mapView?.layer.cornerRadius       = AppLayout.cornerRadius
        mapView?.layer.cornerCurve        = .continuous
        mapView?.clipsToBounds            = true
        mapView?.isUserInteractionEnabled = false
    }

    // MARK: - Populate

    private func iconText(_ label: UILabel?, icon: String, text: String) {
        guard let label,
              let img = UIImage(systemName: icon)?
            .withTintColor(.appTextSecondary, renderingMode: .alwaysOriginal)
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)) else {
            label?.text = text
            return
        }
        let attach    = NSTextAttachment()
        attach.image  = img
        attach.bounds = CGRect(x: 0, y: -3, width: 17, height: 17)
        let full      = NSMutableAttributedString(attachment: attach)
        full.append(NSAttributedString(
            string:     "  \(text)",
            attributes: [.font: AppFont.body(), .foregroundColor: UIColor.appTextSecondary]
        ))
        label.attributedText = full
    }

    private func resetUI() {
        avatarLetter?.text = "?"
        nameLabel?.text    = ""

        statusBadge?.text            = ""
        statusBadge?.backgroundColor = .appTextSecondary

        dniLabel?.text       = ""
        telefonoLabel?.text  = ""
        correoLabel?.text    = ""
        direccionLabel?.text = ""
        fechaLabel?.text     = ""

        mapView?.isHidden         = true
        noLocationLabel?.isHidden = true
        mapView?.removeAnnotations(mapView?.annotations ?? [])

        navigationItem.rightBarButtonItem?.isEnabled = false
    }

    private func populate() {
        guard let c = cliente else {
            resetUI()
            return
        }

        mapView?.isHidden = false
        navigationItem.rightBarButtonItem?.isEnabled = true

        let initial        = c.firstNames.first.map { String($0) } ?? "?"
        avatarLetter?.text = initial.uppercased()
        nameLabel?.text    = c.fullName

        statusBadge?.text            = c.statusValue
        statusBadge?.backgroundColor = c.isActive ? .appSuccess : .appTextSecondary

        iconText(dniLabel,       icon: "creditcard",    text: "DNI: \(c.dniValue)")
        iconText(telefonoLabel,  icon: "phone",         text: c.phoneNumber  ?? "Sin teléfono")
        iconText(correoLabel,    icon: "envelope",      text: c.emailValue   ?? "Sin correo")
        iconText(direccionLabel, icon: "mappin.circle", text: c.addressValue ?? "Sin dirección")
        fechaLabel?.text = "Registrado el \(c.registrationDate.displayDate)"

        if c.hasValidCoordinates {
            noLocationLabel?.isHidden = true
            let coord    = CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude)
            let pin      = MKPointAnnotation()
            pin.title    = c.fullName
            pin.subtitle = c.locationReference
            pin.coordinate = coord
            mapView?.removeAnnotations(mapView?.annotations ?? [])
            mapView?.addAnnotation(pin)
            let region = MKCoordinateRegion(center: coord,
                                            latitudinalMeters: 1500, longitudinalMeters: 1500)
            mapView?.setRegion(region, animated: false)
        } else {
            noLocationLabel?.isHidden = false
            mapView?.removeAnnotations(mapView?.annotations ?? [])
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let cliente else { return }
        if let dest = segue.destination as? FormularioClienteViewController {
            dest.cliente = cliente
            dest.onSave  = { }
        }
    }
}
