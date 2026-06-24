import UIKit
import PhotosUI

// ─────────────────────────────────────────────
// MARK: - ProductoImageService
// ─────────────────────────────────────────────

/// Handles camera/gallery presentation, image resizing, and local file persistence.
final class ProductoImageService: NSObject {

    // MARK: Singleton

    static let shared = ProductoImageService()
    private override init() { super.init() }

    // MARK: State

    private var completion: ((String?) -> Void)?

    // MARK: Public API

    /// Presents an action sheet to choose between camera and gallery, then returns
    /// the saved image file name (stored in the Documents directory) via the completion.
    func presentImagePicker(from viewController: UIViewController,
                            completion: @escaping (String?) -> Void) {
        self.completion = completion

        viewController.showImageSourcePicker(
            onCamera: { [weak self, weak viewController] in
                guard let self, let viewController else { return }
                self.openCamera(from: viewController)
            },
            onGallery: { [weak self, weak viewController] in
                guard let self, let viewController else { return }
                self.openGallery(from: viewController)
            }
        )
    }

    // MARK: Private - Camera

    private func openCamera(from viewController: UIViewController) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        viewController.present(picker, animated: true)
    }

    // MARK: Private - Gallery

    private func openGallery(from viewController: UIViewController) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        viewController.present(picker, animated: true)
    }

    // MARK: Private - Processing

    private func processPickedImage(_ image: UIImage) {
        let resized = image.resized(maxDimension: AppConstants.profileImageMaxDimension)
        let fileName = "\(UUID().compact).jpg"
        let savedPath = resized.saveToDocuments(named: fileName)

        let callback = completion
        completion = nil
        callback?(savedPath)
    }

    private func finishWithNil() {
        let callback = completion
        completion = nil
        callback?(nil)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ProductoImageService: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage else {
            finishWithNil()
            return
        }
        processPickedImage(image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        finishWithNil()
    }
}

// MARK: - PHPickerViewControllerDelegate

extension ProductoImageService: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else {
            finishWithNil()
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self, let image = object as? UIImage else {
                self?.finishWithNil()
                return
            }
            DispatchQueue.main.async { self.processPickedImage(image) }
        }
    }
}
