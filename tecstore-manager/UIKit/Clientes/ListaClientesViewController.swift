import UIKit

final class ListaClientesViewController: UIViewController {

    // MARK: - Data
    private var allClientes:      [FBCliente] = []
    private var filteredClientes: [FBCliente] = []
    private var activeFilter: Int = 0   // 0=Todos 1=Activos 2=Inactivos

    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyLabel: UILabel!

    // MARK: - UI
    private let searchController = UISearchController(searchResultsController: nil)
    private var filterButton:    UIBarButtonItem!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupSearch()
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
        title = "Clientes"
        navigationItem.largeTitleDisplayMode = .never

        filterButton = UIBarButtonItem(
            image:  UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style:  .plain,
            target: self,
            action: #selector(showFilterSheet)
        )
        navigationItem.leftBarButtonItem  = filterButton
    }

    private func setupSearch() {
        searchController.searchResultsUpdater                = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder               = "Buscar por nombre o DNI"
        navigationItem.searchController                      = searchController
        navigationItem.hidesSearchBarWhenScrolling           = false
        definesPresentationContext                           = true
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
        emptyLabel.font      = AppFont.body()
        emptyLabel.textColor = .appTextSecondary
        emptyLabel.isHidden  = true
    }

    private func setupConstraints() {
        view.backgroundColor = .appBackground
    }

    // MARK: - Data

    private func loadData() {
        Task {
            let clientes = (try? await ClienteService.shared.fetchAll()) ?? []
            await MainActor.run { self.allClientes = clientes; self.applyFilters() }
        }
    }

    private func applyFilters() {
        let text = searchController.searchBar.text?.trimmed ?? ""
        var result = text.isEmpty ? allClientes : allClientes.filter {
            $0.fullName.localizedCaseInsensitiveContains(text) || $0.dniValue.contains(text)
        }
        switch activeFilter {
        case 1: result = result.filter {  $0.isActive }
        case 2: result = result.filter { !$0.isActive }
        default: break
        }
        filteredClientes = result
        tableView.reloadData()
        emptyLabel.isHidden = !filteredClientes.isEmpty
        let icon = activeFilter == 0
            ? "line.3.horizontal.decrease.circle"
            : "line.3.horizontal.decrease.circle.fill"
        filterButton.image = UIImage(systemName: icon)
        filterButton.tintColor = activeFilter == 0 ? nil : .brandPrimary
    }

    // MARK: - Actions

    @objc private func showFilterSheet() {
        let titles = ["Todos", "Activos", "Inactivos"]
        let alert  = UIAlertController(title: "Filtrar clientes", message: nil, preferredStyle: .actionSheet)
        titles.enumerated().forEach { idx, name in
            let action = UIAlertAction(title: idx == activeFilter ? "✓ \(name)" : name, style: .default) { [weak self] _ in
                self?.activeFilter = idx
                self?.applyFilters()
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? FormularioClienteViewController {
            dest.cliente = nil
            dest.onSave = { [weak self] in self?.loadData() }
        } else if let dest = segue.destination as? DetalleClienteViewController {
            guard let ip = tableView.indexPathForSelectedRow else { return }
            dest.cliente = filteredClientes[ip.row]
        }
    }
}

extension ListaClientesViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) { applyFilters() }
}

extension ListaClientesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredClientes.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ClienteCell.reuseID, for: indexPath) as! ClienteCell
        cell.configure(with: filteredClientes[indexPath.row])
        return cell
    }
}

extension ListaClientesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let cliente = filteredClientes[indexPath.row]
        let delete  = UIContextualAction(style: .destructive, title: "Eliminar") { [weak self] _, _, done in
            self?.confirmDelete(cliente: cliente)
            done(true)
        }
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }

    private func confirmDelete(cliente: FBCliente) {
        showDestructiveConfirmation(
            title:   "Eliminar cliente",
            message: "¿Eliminar a \"\(cliente.fullName)\"? Esta acción no se puede deshacer."
        ) { [weak self] in
            Task { try? await ClienteService.shared.delete(cliente); await MainActor.run { self?.loadData() } }
        }
    }
}

// MARK: - ClienteCell

final class ClienteCell: UITableViewCell {
    static let reuseID = "ClienteCell"

    private let avatarView   = UIView()
    private let avatarLetter = UILabel()
    private let nameLabel    = UILabel()
    private let dniLabel     = UILabel()
    private let statusBadge  = UILabel()
    private let chevron      = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        buildUI()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); buildUI() }

    private func buildUI() {
        backgroundColor = .appSurface
        contentView.backgroundColor = .appSurface

        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.backgroundColor    = .brandLight
        avatarView.layer.cornerRadius = 22
        avatarView.constrainSize(width: 44, height: 44)

        avatarLetter.translatesAutoresizingMaskIntoConstraints = false
        avatarLetter.font          = AppFont.headline()
        avatarLetter.textColor     = .brandPrimary
        avatarLetter.textAlignment = .center
        avatarView.addSubview(avatarLetter)
        avatarLetter.pinEdges(to: avatarView)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font      = AppFont.headline()
        nameLabel.textColor = .appTextPrimary

        dniLabel.translatesAutoresizingMaskIntoConstraints = false
        dniLabel.font      = AppFont.caption1()
        dniLabel.textColor = .appTextSecondary

        statusBadge.translatesAutoresizingMaskIntoConstraints = false
        statusBadge.font               = AppFont.caption2()
        statusBadge.textColor          = .white
        statusBadge.layer.cornerRadius = 5
        statusBadge.clipsToBounds      = true

        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.tintColor   = .appTextTertiary
        chevron.contentMode = .scaleAspectFit
        chevron.constrainSize(width: 12, height: 16)

        let infoStack = AppStyle.makeVStack(spacing: 3)
        infoStack.addArrangedSubview(nameLabel)
        infoStack.addArrangedSubview(dniLabel)

        contentView.addSubviews(avatarView, infoStack, statusBadge, chevron)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AppLayout.padding),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 10),
            avatarView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            infoStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            infoStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AppLayout.padding),
            chevron.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            statusBadge.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
            statusBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            statusBadge.heightAnchor.constraint(equalToConstant: 22),

            infoStack.trailingAnchor.constraint(lessThanOrEqualTo: statusBadge.leadingAnchor, constant: -8)
        ])
    }

    func configure(with cliente: FBCliente) {
        let initial        = cliente.firstNames.first.map { String($0) } ?? "?"
        avatarLetter.text  = initial.uppercased()
        nameLabel.text     = cliente.fullName
        dniLabel.text      = "DNI: \(cliente.dniValue)"
        statusBadge.text   = "  \(cliente.statusValue)  "
        statusBadge.backgroundColor = cliente.isActive ? .appSuccess : .appTextSecondary
        contentView.alpha  = cliente.isActive ? 1 : 0.6
    }
}
