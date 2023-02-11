import UIKit
import SoraFoundation

final class GovernanceYourDelegationsViewController: UIViewController, ViewHolder {
    typealias RootViewType = GovernanceYourDelegationsViewLayout

    let presenter: GovernanceYourDelegationsPresenterProtocol

    typealias DataSource = UITableViewDiffableDataSource<UITableView.Section, AccountAddress>
    typealias Snapshot = NSDiffableDataSourceSnapshot<UITableView.Section, AccountAddress>

    private lazy var dataSource = createDataSource()
    private var dataStore: [AccountAddress: GovernanceYourDelegationCell.Model] = [:]

    init(presenter: GovernanceYourDelegationsPresenterProtocol, localizationManager: LocalizationManagerProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)

        self.localizationManager = localizationManager
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = GovernanceYourDelegationsViewLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLocalization()
        setupHandlers()

        presenter.setup()
    }

    private func setupLocalization() {
        title = R.string.localizable.governanceReferendumsYourDelegations(
            preferredLanguages: selectedLocale.rLanguages
        )

        rootView.addDelegationButton.imageWithTitleView?.title = R.string.localizable
            .governanceReferendumsAddDelegation(
                preferredLanguages: selectedLocale.rLanguages
            )
    }

    private func setupHandlers() {
        rootView.tableView.delegate = self

        rootView.addDelegationButton.addTarget(
            self,
            action: #selector(actionAddDelegation),
            for: .touchUpInside
        )
    }

    private func createDataSource() -> DataSource {
        .init(tableView: rootView.tableView) { [weak self] tableView, indexPath, identifier -> UITableViewCell? in
            guard let self = self, let model = self.dataStore[identifier]  else {
                return nil
            }

            let cell: GovernanceYourDelegationCell = tableView.dequeueReusableCell(for: indexPath)
            cell.bind(viewModel: model, locale: self.selectedLocale)
            return cell
        }
    }

    @objc private func actionAddDelegation() {
        presenter.addDelegation()
    }
}

extension GovernanceYourDelegationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let address = dataSource.itemIdentifier(for: indexPath) else {
            return
        }

        presenter.selectDelegate(for: address)
    }
}

extension GovernanceYourDelegationsViewController: GovernanceYourDelegationsViewProtocol {
    func didReceive(viewModels: [GovernanceYourDelegationCell.Model]) {
        dataStore = viewModels.reduce(into: [AccountAddress: GovernanceYourDelegationCell.Model]()) { accum, model in
            accum[model.identifier] = model
        }

        let identifiers = viewModels.map { $0.identifier }

        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(identifiers)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension GovernanceYourDelegationsViewController: Localizable {
    func applyLocalization() {
        if isViewLoaded {
            setupLocalization()
        }
    }
}
