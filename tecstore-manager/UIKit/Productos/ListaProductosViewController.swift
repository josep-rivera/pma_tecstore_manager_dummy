import UIKit

final class ListaProductosViewController: UIViewController {

    // MARK: - Data
    private var allProductos:      [FBProducto] = []
    private var filteredProductos: [FBProducto] = []
    private var activeFilter: Int = 0   // 0=Todos 1=Con stock 2=Sin stock

    // MARK: - IBOutlets
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!

    // MARK: - UI Elements (programmatic — not IBOutlets)
    private let searchController = UISearchController(searchResultsController: nil)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupSearch()
        setupSegmentedControl()
        setupTableView()
        setupEmptyLabel()
        setupConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    // MARK: - Setup

    private func setupNavigation() {
        title = "Productos"
        navigationItem.largeTitleDisplayMode = .never
    }

    private func setupSegmentedControl() {
        segmentedControl.selectedSegmentIndex = 0
        // segmentChanged wired via @IBAction in storyboard
    }

    private func setupSearch() {
        searchController.searchResultsUpdater               = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder              = "Buscar por nombre, código o categoría"
        navigationItem.searchController                     = searchController
        navigationItem.hidesSearchBarWhenScrolling          = false
        definesPresentationContext                          = true
    }

    private func setupTableView() {
        tableView.dataSource         = self
        tableView.delegate           = self
        tableView.rowHeight          = UITableView.automaticDimension
        tableView.estimatedRowHeight = AppLayout.cellHeight
        tableView.backgroundColor    = .appBackground
        tableView.separatorInset     = UIEdgeInsets(top: 0, left: AppLayout.padding, bottom: 0, right: 0)
    }

    private func setupEmptyLabel() {
        // emptyLabel is storyboard-placed; apply styling only
        emptyLabel.font          = AppFont.body()
        emptyLabel.textColor     = .appTextSecondary
        emptyLabel.isHidden      = true
    }

    private func setupConstraints() {
        view.backgroundColor = .appBackground
    }

    // MARK: - Data

    private func loadData() {
        Task {
            let productos = (try? await ProductoService.shared.fetchAll()) ?? []
            await MainActor.run { self.allProductos = productos; self.applyFilters() }
        }
    }

    private func applyFilters() {
        let text = searchController.searchBar.text?.trimmed ?? ""
        var result = text.isEmpty ? allProductos : allProductos.filter {
            $0.productName.localizedCaseInsensitiveContains(text) ||
            $0.productCode.localizedCaseInsensitiveContains(text) ||
            $0.categoryValue.localizedCaseInsensitiveContains(text)
        }
        switch activeFilter {
        case 1: result = result.filter {  $0.hasStock }
        case 2: result = result.filter { !$0.hasStock }
        default: break
        }
        filteredProductos = result
        tableView.reloadData()
        emptyLabel.isHidden = !filteredProductos.isEmpty
    }

    // MARK: - Actions

    @IBAction @objc private func segmentChanged(_ sender: UISegmentedControl) {
        activeFilter = segmentedControl.selectedSegmentIndex
        applyFilters()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? FormularioProductoViewController {
            dest.producto = nil
            dest.onSave   = { [weak self] in self?.loadData() }
        } else if let dest = segue.destination as? DetalleProductoViewController {
            guard let ip = tableView.indexPathForSelectedRow else { return }
            dest.producto = filteredProductos[ip.row]
        }
    }
}

// MARK: - UISearchResultsUpdating

extension ListaProductosViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFilters()
    }
}

// MARK: - UITableViewDataSource

extension ListaProductosViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredProductos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProductoCell.reuseID, for: indexPath) as! ProductoCell
        cell.configure(with: filteredProductos[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ListaProductosViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let product = filteredProductos[indexPath.row]
        let delete  = UIContextualAction(style: .destructive, title: "Eliminar") { [weak self] _, _, completion in
            self?.confirmDelete(product: product, at: indexPath)
            completion(true)
        }
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }

    private func confirmDelete(product: FBProducto, at indexPath: IndexPath) {
        showDestructiveConfirmation(
            title:   "Eliminar producto",
            message: "¿Eliminar \"\(product.productName)\"? Esta acción no se puede deshacer."
        ) { [weak self] in
            Task { try? await ProductoService.shared.delete(product); await MainActor.run { self?.loadData() } }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - ProductoCell
// ─────────────────────────────────────────────

final class ProductoCell: UITableViewCell {

    static let reuseID = "ProductoCell"

    private let thumbnailView = UIImageView()
    private let nombreLabel   = UILabel()
    private let codigoLabel   = UILabel()
    private let precioLabel   = UILabel()
    private let stockLabel    = UILabel()
    private let chevron       = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        buildUI()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); buildUI() }

    private func buildUI() {
        backgroundColor = .appSurface
        contentView.backgroundColor = .appSurface

        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.contentMode         = .scaleAspectFill
        thumbnailView.clipsToBounds       = true
        thumbnailView.layer.cornerRadius  = 8
        thumbnailView.constrainSize(width: 44, height: 44)

        nombreLabel.translatesAutoresizingMaskIntoConstraints = false
        nombreLabel.font      = AppFont.headline()
        nombreLabel.textColor = .appTextPrimary
        nombreLabel.numberOfLines = 1

        codigoLabel.translatesAutoresizingMaskIntoConstraints = false
        codigoLabel.font      = AppFont.caption1()
        codigoLabel.textColor = .appTextSecondary

        precioLabel.translatesAutoresizingMaskIntoConstraints = false
        precioLabel.font          = AppFont.subheadline()
        precioLabel.textColor     = .brandPrimary
        precioLabel.textAlignment = .right

        stockLabel.translatesAutoresizingMaskIntoConstraints = false
        stockLabel.font          = AppFont.caption1()
        stockLabel.textAlignment = .right

        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.tintColor   = .appTextTertiary
        chevron.contentMode = .scaleAspectFit
        chevron.constrainSize(width: 12, height: 16)

        let leftStack = AppStyle.makeVStack(spacing: 3)
        leftStack.addArrangedSubview(nombreLabel)
        leftStack.addArrangedSubview(codigoLabel)

        let rightStack = AppStyle.makeVStack(spacing: 3)
        rightStack.alignment = .trailing
        rightStack.addArrangedSubview(precioLabel)
        rightStack.addArrangedSubview(stockLabel)

        contentView.addSubviews(thumbnailView, leftStack, rightStack, chevron)

        NSLayoutConstraint.activate([
            thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppLayout.padding),
            thumbnailView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            leftStack.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor, constant: 12),
            leftStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            leftStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),
            leftStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),

            chevron.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppLayout.padding),
            chevron.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            rightStack.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
            rightStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rightStack.leadingAnchor.constraint(greaterThanOrEqualTo: leftStack.trailingAnchor, constant: 8)
        ])
    }

    func configure(with producto: FBProducto) {
        nombreLabel.text     = producto.productName
        codigoLabel.text     = "\(producto.productCode) · \(producto.categoryValue)"
        precioLabel.text     = producto.priceDouble.asCurrency
        stockLabel.text      = "\(producto.stockInt) ud. — \(producto.stockInt.stockLabel)"
        stockLabel.textColor = producto.stockInt.stockUIColor
        contentView.alpha    = producto.isActive ? 1 : 0.5

        let catColor = UIColor.colorForCategory(producto.categoryValue)
        let catIcon  = producto.categoryEnum.icon
        thumbnailView.backgroundColor = catColor.withAlphaComponent(0.15)
        thumbnailView.tintColor       = catColor
        thumbnailView.setImage(
            from: producto.productImagePath,
            placeholder: UIImage(systemName: catIcon)?
                .withTintColor(catColor, renderingMode: .alwaysOriginal)
        )
    }
}
