import UIKit

// ─────────────────────────────────────────────
// MARK: - ProductFormValidation
// ─────────────────────────────────────────────

struct ProductFormValidation {
    let nameError: String?
    let categoryError: String?
    let priceError: String?
    let stockError: String?

    var isValid: Bool {
        nameError == nil && categoryError == nil && priceError == nil && stockError == nil
    }

    static let valid = ProductFormValidation(nameError: nil, categoryError: nil,
                                             priceError: nil, stockError: nil)
}

struct ProductFormValues {
    let name: String
    let category: String
    let price: String
    let stock: String
    let isActive: Bool
}

// ─────────────────────────────────────────────
// MARK: - FormularioProductoViewModel
// ─────────────────────────────────────────────

final class FormularioProductoViewModel {

    // MARK: Outputs

    var onLoading: ((Bool) -> Void)?
    var onError: ((String) -> Void)?
    var onSuccess: (() -> Void)?
    var onValidationErrors: ((ProductFormValidation) -> Void)?
    var onCodeGenerated: ((String) -> Void)?
    var onPhotoPreview: ((UIImage?) -> Void)?
    var onCategoryChanged: ((String) -> Void)?
    var onEstadoChanged: ((Bool) -> Void)?
    var onFormValuesChanged: ((ProductFormValues) -> Void)?

    // MARK: State

    private(set) var product: FBProducto?
    private var isEditMode: Bool { product != nil }

    private var name: String = ""
    private var category: String = ProductCategory.otros.rawValue
    private var price: String = ""
    private var stock: String = ""
    private var isActive: Bool = true
    private var photoPath: String?
    private var generatedCode: String = ""

    private var hasAttemptedSubmit = false

    // MARK: Configuration

    func configure(with product: FBProducto?) {
        self.product = product

        if let product {
            generatedCode = product.productCode
            name = product.productName
            category = product.categoryValue
            price = String(format: "%.2f", product.priceDouble)
            stock = "\(product.stockInt)"
            isActive = product.isActive
            photoPath = product.productImagePath

            onCodeGenerated?(generatedCode)
            onCategoryChanged?(category)
            onEstadoChanged?(isActive)
            emitFormValues()
            onPhotoPreview?(loadPreviewImage())
        } else {
            category = ProductCategory.otros.rawValue
            onCategoryChanged?(category)
            emitFormValues()
            refreshCode()
        }
    }

    private func emitFormValues() {
        onFormValuesChanged?(
            ProductFormValues(name: name, category: category, price: price,
                              stock: stock, isActive: isActive)
        )
    }

    // MARK: Inputs

    func updateName(_ value: String) {
        name = value.trimmed
        emitFormValues()
        if hasAttemptedSubmit { validate() }
    }

    func updateCategory(_ value: String) {
        category = value.trimmed
        onCategoryChanged?(category)
        emitFormValues()
        if !isEditMode { refreshCode() }
        if hasAttemptedSubmit { validate() }
    }

    func updatePrice(_ value: String) {
        price = value.trimmed
        emitFormValues()
        if hasAttemptedSubmit { validate() }
    }

    func updateStock(_ value: String) {
        stock = value.trimmed
        emitFormValues()
        if hasAttemptedSubmit { validate() }
    }

    func updateEstado(_ isOn: Bool) {
        isActive = isOn
        onEstadoChanged?(isActive)
        emitFormValues()
    }

    func updatePhotoPath(_ path: String?) {
        photoPath = path
        onPhotoPreview?(loadPreviewImage())
    }

    func photoTapped(from viewController: UIViewController) {
        ProductoImageService.shared.presentImagePicker(from: viewController) { [weak self] path in
            self?.updatePhotoPath(path)
        }
    }

    // MARK: Save

    func save() {
        hasAttemptedSubmit = true
        let validation = performValidation()
        onValidationErrors?(validation)
        guard validation.isValid else { return }

        let priceValue = Double(price) ?? 0
        let stockValue = Int(stock) ?? 0
        let status = isActive ? "Activo" : "Inactivo"
        let finalPhotoPath = photoPath ?? product?.productImagePath
        let code = generatedCode

        onLoading?(true)
        Task { [weak self] in
            guard let self else { return }
            do {
                if let product = self.product {
                    try await ProductoService.shared.update(
                        product,
                        code: code,
                        name: self.name,
                        category: self.category,
                        price: priceValue,
                        stock: stockValue,
                        photoPath: finalPhotoPath,
                        estado: status
                    )
                } else {
                    try await ProductoService.shared.create(
                        code: code,
                        name: self.name,
                        category: self.category,
                        price: priceValue,
                        stock: stockValue,
                        photoPath: finalPhotoPath
                    )
                }
                await MainActor.run {
                    self.onLoading?(false)
                    self.onSuccess?()
                }
            } catch let error as ServiceError {
                await MainActor.run {
                    self.onLoading?(false)
                    self.onError?(error.errorDescription ?? "")
                }
            } catch {
                await MainActor.run {
                    self.onLoading?(false)
                    self.onError?(error.localizedDescription)
                }
            }
        }
    }

    // MARK: Private

    private func refreshCode() {
        guard !isEditMode else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let code = try await ProductoService.shared.generateCode(for: self.category)
                await MainActor.run {
                    self.generatedCode = code
                    self.onCodeGenerated?(code)
                }
            } catch {
                // Keep the existing code if generation fails; validation or save will surface errors.
            }
        }
    }

    private func validate() {
        let validation = performValidation()
        onValidationErrors?(validation)
    }

    private func performValidation() -> ProductFormValidation {
        let nameError: String? = name.isEmpty ? "Name is required." : nil
        let categoryError: String? = category.isEmpty ? "Select a category." : nil

        let priceError: String?
        if price.isEmpty {
            priceError = "Price is required."
        } else if Decimal(string: price) == nil {
            priceError = "Enter a valid price."
        } else if let decimal = Decimal(string: price), decimal <= 0 {
            priceError = "Price must be greater than 0."
        } else {
            priceError = nil
        }

        let stockError: String?
        if stock.isEmpty {
            stockError = "Stock is required."
        } else if let value = Int(stock), value < 0 {
            stockError = "Stock cannot be negative."
        } else if Int(stock) == nil {
            stockError = "Enter a valid stock."
        } else {
            stockError = nil
        }

        return ProductFormValidation(nameError: nameError,
                                     categoryError: categoryError,
                                     priceError: priceError,
                                     stockError: stockError)
    }

    private func loadPreviewImage() -> UIImage? {
        guard let path = photoPath, !path.isEmpty else { return nil }
        return UIImage(named: path) ?? UIImage.fromDocuments(named: path)
    }
}
