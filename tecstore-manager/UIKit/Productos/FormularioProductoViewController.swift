import UIKit

final class FormularioProductoViewController: UIViewController {

    // MARK: - Mode

    var producto: FBProducto? {
        didSet { viewModel.configure(with: producto) }
    }
    var onSave: (() -> Void)?

    private let viewModel = FormularioProductoViewModel()

    // ── Category picker state
    private let categories = ProductCategory.allCases.map(\.rawValue)
    private var categoryPickerView = UIPickerView()

    // MARK: - IBOutlets
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var nombreField: UITextField!
    @IBOutlet weak var categoriaField: UITextField!
    @IBOutlet weak var precioField: UITextField!
    @IBOutlet weak var stockField: UITextField!
    @IBOutlet weak var estadoSwitch: UISwitch!

    // MARK: - UI
    @IBOutlet weak var nombreError: UILabel!
    @IBOutlet weak var categoriaError: UILabel!
    @IBOutlet weak var precioError: UILabel!
    @IBOutlet weak var stockError: UILabel!

    @IBOutlet weak var estadoLabel: UILabel!
    @IBOutlet weak var estadoValueLabel: UILabel!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupPhoto()
        setupFields()
        setupErrorLabels()
        setupEstado()
        setupKeyboard()
        bindViewModel()
        viewModel.configure(with: producto)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .appBackground
        title = producto != nil ? "Edit Product" : "New Product"
        navigationItem.largeTitleDisplayMode = .never

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupPhoto() {
        photoImageView.contentMode        = .center
        photoImageView.clipsToBounds      = true
        photoImageView.layer.cornerRadius = AppLayout.cornerRadius
        photoImageView.layer.cornerCurve  = .continuous
        photoImageView.layer.borderWidth  = 1.5
        photoImageView.layer.borderColor  = UIColor.brandLight.cgColor
        photoImageView.backgroundColor    = .appSurface

        let cameraIcon = UIImage(systemName: "camera.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 28, weight: .light))
            .withRenderingMode(.alwaysTemplate)
        photoImageView.image     = cameraIcon
        photoImageView.tintColor = .appTextTertiary
    }

    private func setupFields() {
        let configs: [(UITextField, String, String, UIKeyboardType, UIReturnKeyType)] = [
            (nombreField,    "Nombre del producto",   "tag",           .default,       .next),
            (precioField,    "0.00",                  "dollarsign.circle", .decimalPad, .done),
            (stockField,     "0",                     "number",        .numberPad,    .done)
        ]
        for (field, ph, icon, keyboard, ret) in configs {
            AppStyle.style(textField: field, placeholder: ph, icon: icon,
                           keyboardType: keyboard, returnKey: ret)
            field.delegate = self
        }
        nombreField.autocapitalizationType = .words

        AppStyle.style(textField: categoriaField, placeholder: "Selecciona una categoría", icon: "tag.fill")
        categoriaField.text = ProductCategory.otros.rawValue
        categoriaField.tintColor = .clear

        categoryPickerView.delegate   = self
        categoryPickerView.dataSource = self
        categoriaField.inputView      = categoryPickerView

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn   = UIBarButtonItem(title: "Done", style: .prominent,
                                         target: self, action: #selector(categoryPickerDone))
        toolbar.setItems([flexSpace, doneBtn], animated: false)
        categoriaField.inputAccessoryView = toolbar
    }

    private func setupEstado() {
        estadoSwitch.isOn = true
        estadoSwitch.onTintColor = .appSuccess

        estadoLabel.text      = "Estado"
        estadoLabel.font      = AppFont.subheadline()
        estadoLabel.textColor = .appTextSecondary

        estadoValueLabel.font      = AppFont.subheadline()
        estadoValueLabel.textColor = .appSuccess
        estadoValueLabel.text      = "Activo"
    }

    private func setupErrorLabels() {
        for label in ([nombreError, categoriaError, precioError, stockError] as [UILabel]) {
            label.font          = AppFont.caption1()
            label.textColor     = .appError
            label.numberOfLines = 0
            label.isHidden      = true
        }
    }

    private func setupKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - ViewModel Binding

    private func bindViewModel() {
        viewModel.onValidationErrors = { [weak self] validation in
            self?.apply(validation: validation)
        }
        viewModel.onCategoryChanged = { [weak self] category in
            self?.categoriaField.text = category
            if let index = self?.categories.firstIndex(of: category) {
                self?.categoryPickerView.selectRow(index, inComponent: 0, animated: false)
            }
        }
        viewModel.onEstadoChanged = { [weak self] isActive in
            self?.estadoSwitch.isOn = isActive
            self?.updateEstadoLabel()
        }
        viewModel.onFormValuesChanged = { [weak self] values in
            self?.nombreField.text = values.name
            self?.categoriaField.text = values.category
            self?.precioField.text = values.price
            self?.stockField.text = values.stock
        }
        viewModel.onPhotoPreview = { [weak self] image in
            self?.photoImageView.contentMode = image == nil ? .center : .scaleAspectFill
            self?.photoImageView.image       = image ?? self?.defaultCameraIcon()
            self?.photoImageView.tintColor   = image == nil ? .appTextTertiary : nil
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

    private func defaultCameraIcon() -> UIImage? {
        UIImage(systemName: "camera.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 28, weight: .light))
            .withRenderingMode(.alwaysTemplate)
    }

    private func apply(validation: ProductFormValidation) {
        updateErrorLabel(nombreError, for: nombreField, message: validation.nameError)
        updateErrorLabel(categoriaError, for: categoriaField, message: validation.categoryError)
        updateErrorLabel(precioError, for: precioField, message: validation.priceError)
        updateErrorLabel(stockError, for: stockField, message: validation.stockError)
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

    // MARK: - Actions

    @IBAction @objc private func handleSave(_ sender: Any) {
        viewModel.save()
    }

    @IBAction @objc private func handleSelectPhoto(_ sender: UIButton) {
        viewModel.photoTapped(from: self)
    }

    @objc private func categoryPickerDone() {
        categoriaField.resignFirstResponder()
        let row = categoryPickerView.selectedRow(inComponent: 0)
        let selected = categories[row]
        categoriaField.text = selected
        viewModel.updateCategory(selected)
    }

    @IBAction @objc private func estadoChanged(_ sender: UISwitch) {
        viewModel.updateEstado(sender.isOn)
    }

    private func updateEstadoLabel() {
        estadoValueLabel.text      = estadoSwitch.isOn ? "Activo" : "Inactivo"
        estadoValueLabel.textColor = estadoSwitch.isOn ? .appSuccess : .appTextSecondary
    }

    @IBAction @objc private func fieldsChanged(_ sender: UITextField) {
        switch sender {
        case nombreField:    viewModel.updateName(sender.text ?? "")
        case precioField:    viewModel.updatePrice(sender.text ?? "")
        case stockField:     viewModel.updateStock(sender.text ?? "")
        default: break
        }
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

// MARK: - UITextFieldDelegate

extension FormularioProductoViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nombreField:    categoriaField.becomeFirstResponder()
        case categoriaField: precioField.becomeFirstResponder()
        case precioField:    stockField.becomeFirstResponder()
        default:             textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - UIPickerViewDataSource / Delegate

extension FormularioProductoViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        categories.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        categories[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoriaField.text = categories[row]
        viewModel.updateCategory(categories[row])
    }
}
