import UIKit
import MapKit
import CoreLocation

final class FormularioClienteViewController: UIViewController {

    // MARK: - Mode

    var cliente: FBCliente? {
        didSet { viewModel.configure(with: cliente) }
    }
    var onSave: (() -> Void)?

    private let viewModel = FormularioClienteViewModel()

    // MARK: - IBOutlets
    @IBOutlet weak var dniField: UITextField!
    @IBOutlet weak var nombresField: UITextField!
    @IBOutlet weak var apellidosField: UITextField!
    @IBOutlet weak var telefonoField: UITextField!
    @IBOutlet weak var correoField: UITextField!
    @IBOutlet weak var direccionField: UITextField!
    @IBOutlet weak var estadoSwitch: UISwitch!
    @IBOutlet weak var mapView: MKMapView!

    // MARK: - UI
    @IBOutlet weak var dniError: UILabel!
    @IBOutlet weak var nombresError: UILabel!
    @IBOutlet weak var apellidosError: UILabel!
    @IBOutlet weak var correoError: UILabel!

    @IBOutlet weak var estadoLabel: UILabel!
    @IBOutlet weak var estadoValueLabel: UILabel!

    @IBOutlet weak var locationHeaderLabel: UILabel!
    @IBOutlet weak var mapHintLabel: UILabel!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupFields()
        setupErrorLabels()
        setupEstado()
        setupLocationSection()
        setupKeyboard()
        bindViewModel()
        viewModel.configure(with: cliente)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            let tabBarHeight = tabBarController?.tabBar.frame.height ?? 0
            if scrollView.contentInset.bottom == 0 {
                scrollView.contentInset.bottom = tabBarHeight + AppLayout.padding
                scrollView.verticalScrollIndicatorInsets.bottom = tabBarHeight
            }
        }
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .appBackground
        title = cliente != nil ? "Edit Client" : "New Client"
        navigationItem.largeTitleDisplayMode = .never

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupFields() {
        let configs: [(UITextField, String, String, UIKeyboardType, UIReturnKeyType, Bool)] = [
            (dniField,       "DNI (8 digits)",          "creditcard",  .numberPad,    .next, false),
            (nombresField,   "First names",             "person",      .default,      .next, false),
            (apellidosField, "Last names",              "person.fill", .default,      .next, false),
            (telefonoField,  "Phone (optional)",        "phone",       .phonePad,     .next, false),
            (correoField,    "Email (optional)",        "envelope",    .emailAddress, .next, false),
            (direccionField, "Address (optional)",      "mappin",      .default,      .done, false)
        ]
        for (field, ph, icon, kb, ret, sec) in configs {
            AppStyle.style(textField: field, placeholder: ph, icon: icon,
                           isSecure: sec, keyboardType: kb, returnKey: ret)
            field.delegate = self
        }
        nombresField.autocapitalizationType   = .words
        apellidosField.autocapitalizationType = .words
        direccionField.autocapitalizationType = .words
    }

    private func setupEstado() {
        estadoSwitch.isOn        = true
        estadoSwitch.onTintColor = .appSuccess

        estadoLabel.text      = "Status"
        estadoLabel.font      = AppFont.subheadline()
        estadoLabel.textColor = .appTextSecondary

        estadoValueLabel.font      = AppFont.subheadline()
        estadoValueLabel.textColor = .appSuccess
        estadoValueLabel.text      = "Active"
    }

    private func setupErrorLabels() {
        for label in ([dniError, nombresError, apellidosError, correoError] as [UILabel]) {
            label.font          = AppFont.caption1()
            label.textColor     = .appError
            label.numberOfLines = 0
            label.isHidden      = true
        }
    }

    private func setupLocationSection() {
        mapView.layer.cornerRadius = AppLayout.cornerRadius
        mapView.clipsToBounds      = true
        mapView.delegate           = self

        mapHintLabel.text          = "Tap the map to place the pin"
        mapHintLabel.font          = AppFont.caption1()
        mapHintLabel.textColor     = .appTextSecondary
        mapHintLabel.textAlignment = .center

        let tap = UITapGestureRecognizer(target: self, action: #selector(mapTapped(_:)))
        mapView.addGestureRecognizer(tap)
    }

    private func setupKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        viewModel.cancelPendingGeocode()
    }

    // MARK: - ViewModel Binding

    private func bindViewModel() {
        viewModel.onValidationErrors = { [weak self] validation in
            self?.apply(validation: validation)
        }
        viewModel.onSaveEnabled = { [weak self] isEnabled in
            self?.navigationItem.rightBarButtonItem?.isEnabled = isEnabled
        }
        viewModel.onCoordinateUpdate = { [weak self] coordinate in
            self?.setMapPin(coordinate)
        }
        viewModel.onSuggestedAddress = { [weak self] address in
            self?.direccionField.text = address
        }
        viewModel.onFormValuesChanged = { [weak self] values in
            self?.dniField.text = values.dni
            self?.nombresField.text = values.firstNames
            self?.apellidosField.text = values.lastNames
            self?.telefonoField.text = values.phone
            self?.correoField.text = values.email
            self?.direccionField.text = values.address
        }
        viewModel.onEstadoChanged = { [weak self] isActive in
            self?.estadoSwitch.isOn = isActive
            self?.updateEstadoLabel()
        }
        viewModel.onLoading = { [weak self] isLoading in
            self?.navigationItem.rightBarButtonItem?.isEnabled = !isLoading
        }
        viewModel.onError = { [weak self] message in
            self?.showAlert(title: "Save Error", message: message)
        }
        viewModel.onSuccess = { [weak self] in
            self?.onSave?()
            self?.navigationController?.popViewController(animated: true)
        }
    }

    private func apply(validation: ClientFormValidation) {
        updateErrorLabel(dniError, for: dniField, message: validation.dniError)
        updateErrorLabel(nombresError, for: nombresField, message: validation.firstNamesError)
        updateErrorLabel(apellidosError, for: apellidosField, message: validation.lastNamesError)
        updateErrorLabel(correoError, for: correoField, message: validation.emailError)
    }

    private func updateErrorLabel(_ label: UILabel, for field: UITextField, message: String?) {
        if let message {
            label.text = message
            label.isHidden = false
            AppStyle.markFieldError(field, hasError: true)
        } else {
            label.isHidden = true
            AppStyle.markFieldError(field, hasError: false)
        }
    }

    // MARK: - Map Helpers

    private func setMapPin(_ coordinate: CLLocationCoordinate2D?) {
        mapView.removeAnnotations(mapView.annotations)

        guard let coordinate else {
            centerMapOnLima()
            return
        }

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)

        let region = MKCoordinateRegion(center: coordinate,
                                        latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)

        mapHintLabel.text      = "Pin placed · tap to move"
        mapHintLabel.textColor = .brandPrimary
    }

    private func centerMapOnLima() {
        let lima   = CLLocationCoordinate2D(latitude: -12.0464, longitude: -77.0428)
        let region = MKCoordinateRegion(center: lima,
                                        latitudinalMeters: 10_000, longitudinalMeters: 10_000)
        mapView.setRegion(region, animated: false)
    }

    // MARK: - Actions

    @IBAction private func handleSave(_ sender: Any) {
        viewModel.save()
    }

    @objc private func mapTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        viewModel.updateCoordinate(coordinate)
    }

    @IBAction @objc private func direccionChanged(_ sender: UITextField) {
        viewModel.updateAddress(sender.text ?? "")
    }

    @IBAction @objc private func estadoChanged(_ sender: UISwitch) {
        viewModel.updateEstado(sender.isOn)
    }

    private func updateEstadoLabel() {
        estadoValueLabel.text      = estadoSwitch.isOn ? "Active" : "Inactive"
        estadoValueLabel.textColor = estadoSwitch.isOn ? .appSuccess : .appTextSecondary
    }

    @IBAction @objc private func fieldsChanged(_ sender: UITextField) {
        switch sender {
        case nombresField:   viewModel.updateFirstNames(sender.text ?? "")
        case apellidosField: viewModel.updateLastNames(sender.text ?? "")
        case telefonoField:  viewModel.updatePhone(sender.text ?? "")
        case correoField:    viewModel.updateEmail(sender.text ?? "")
        default: break
        }
    }

    @IBAction @objc private func dniChanged(_ sender: UITextField) {
        let sanitized = viewModel.sanitizeDNILength(sender.text ?? "")
        dniField.text = sanitized
        viewModel.updateDNI(sanitized)
    }

    @objc private func tapToDismiss() { view.endEditing(true) }

    @objc private func keyboardWillShow(_ n: NSNotification) {
        if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
           let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.contentInset.bottom = frame.height + 20
        }
    }
    @objc private func keyboardWillHide(_ n: NSNotification) {
        if let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.contentInset.bottom = 0
        }
    }
}

extension FormularioClienteViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case dniField:       nombresField.becomeFirstResponder()
        case nombresField:   apellidosField.becomeFirstResponder()
        case apellidosField: telefonoField.becomeFirstResponder()
        case telefonoField:  correoField.becomeFirstResponder()
        case correoField:    direccionField.becomeFirstResponder()
        default:             textField.resignFirstResponder()
        }
        return true
    }
}

extension FormularioClienteViewController: MKMapViewDelegate {}
