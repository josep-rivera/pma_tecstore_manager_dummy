import UIKit
import SwiftUI
import Combine

// MARK: - InicioViewController

final class InicioViewController: UIViewController {
    private let viewModel = InicioViewModel()
    private var hosting: UIHostingController<InicioView>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Inicio"
        navigationItem.largeTitleDisplayMode = .always

        hosting = UIHostingController(rootView: InicioView(
            viewModel: viewModel,
            onBusquedas:  { [weak self] in self?.performSegue(withIdentifier: "showBusquedas", sender: nil) },
            onReportes:   { [weak self] in self?.performSegue(withIdentifier: "showReportes", sender: nil) },
            onStockBajo:  { [weak self] in self?.performSegue(withIdentifier: "showStockBajo", sender: nil) },
            onNuevaVenta: { [weak self] in self?.performSegue(withIdentifier: "showNuevaVentaModal", sender: nil) }
        ))
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}

// MARK: - ListaVentasViewController

final class ListaVentasViewController: UIViewController {

    private let ventasVM   = ListaVentasViewModel()
    private var hosting:   UIHostingController<ListaVentasView>!
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ventas"
        navigationItem.largeTitleDisplayMode = .always

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain, target: self, action: #selector(addSale))
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain, target: self, action: #selector(showFilter))

        hosting = UIHostingController(rootView: ListaVentasView(
            viewModel: ventasVM,
            onSelectVenta: { [weak self] venta in self?.pushDetalle(venta) },
            onAddSale:     { [weak self] in self?.addSale() }
        ))
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)

        ventasVM.$isDateFiltering
            .receive(on: RunLoop.main)
            .sink { [weak self] filtering in
                let icon = filtering ? "line.3.horizontal.decrease.circle.fill"
                                     : "line.3.horizontal.decrease.circle"
                self?.navigationItem.leftBarButtonItem?.image = UIImage(systemName: icon)
                self?.navigationItem.leftBarButtonItem?.tintColor = filtering ? .brandPrimary : nil
            }
            .store(in: &cancellables)
    }

    @objc private func addSale() {
        performSegue(withIdentifier: "showRegistroVenta", sender: nil)
    }

    @objc private func showFilter() {
        ventasVM.showDateFilter = true
    }

    private func pushDetalle(_ venta: FBVenta) {
        performSegue(withIdentifier: "showDetalleVenta", sender: venta)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetalleVenta",
           let dest = segue.destination as? DetalleVentaViewController,
           let venta = sender as? FBVenta {
            dest.venta = venta
        }
    }
}

// MARK: - PerfilViewController

final class PerfilViewController: UIViewController {
    private let viewModel = PerfilViewModel()
    private var hosting: UIHostingController<PerfilView>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Configuración"
        navigationItem.largeTitleDisplayMode = .always

        hosting = UIHostingController(rootView: PerfilView(
            onAcercaDe: { [weak self] in
                self?.performSegue(withIdentifier: "showAcercaDe", sender: nil)
            },
            viewModel: viewModel
        ))
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}

// MARK: - RegistroVentaViewController
// RegistroVentaView requires an onSave callback.
// When used standalone (not modal), dismissing is handled by the navigation stack.

final class RegistroVentaViewController: UIViewController {
    private let viewModel = RegistroVentaViewModel()
    private var hosting: UIHostingController<RegistroVentaView>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Nueva venta"
        navigationItem.largeTitleDisplayMode = .never

        let swiftUIView = RegistroVentaView(
            onSave: { [weak self] in
                if self?.presentingViewController != nil {
                    self?.dismiss(animated: true)
                } else {
                    self?.navigationController?.popViewController(animated: true)
                }
            },
            viewModel: viewModel
        )

        hosting = UIHostingController(rootView: swiftUIView)
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}

// MARK: - DetalleVentaViewController
// DetalleVentaView requires an FBVenta object.
// Inject via the venta property before or after instantiation.

final class DetalleVentaViewController: UIViewController {
    private var viewModel: DetalleVentaViewModel?
    private var hosting: UIHostingController<AnyView>!

    var venta: FBVenta? {
        didSet {
            if let venta {
                viewModel = DetalleVentaViewModel(venta: venta)
                hosting?.rootView = AnyView(DetalleVentaView(viewModel: viewModel!))
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Detalle de venta"
        navigationItem.largeTitleDisplayMode = .never

        if let venta {
            viewModel = DetalleVentaViewModel(venta: venta)
        }
        let content: AnyView = viewModel.map { AnyView(DetalleVentaView(viewModel: $0)) } ?? AnyView(EmptyView())
        hosting = UIHostingController(rootView: content)
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}

// MARK: - BusquedasViewController

final class BusquedasViewController: UIViewController {
    private let viewModel = BusquedasViewModel()
    private var hosting: UIHostingController<BusquedasView>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Búsquedas"
        navigationItem.largeTitleDisplayMode = .always

        hosting = UIHostingController(rootView: BusquedasView(viewModel: viewModel))
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}

// MARK: - ReportesViewController

final class ReportesViewController: UIViewController {
    private let viewModel = ReportesViewModel()
    private var hosting: UIHostingController<ReportesView>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Reportes"
        navigationItem.largeTitleDisplayMode = .always

        hosting = UIHostingController(rootView: ReportesView(viewModel: viewModel))
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}

// MARK: - StockBajoViewController

final class StockBajoViewController: UIViewController {
    private let viewModel = StockBajoViewModel()
    private var hosting: UIHostingController<StockBajoView>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Stock bajo"
        navigationItem.largeTitleDisplayMode = .never

        hosting = UIHostingController(rootView: StockBajoView(viewModel: viewModel))
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}

// MARK: - AcercaDeViewController

final class AcercaDeViewController: UIViewController {
    private var hosting: UIHostingController<AcercaDeView>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Acerca de"
        navigationItem.largeTitleDisplayMode = .never

        hosting = UIHostingController(rootView: AcercaDeView())
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}
