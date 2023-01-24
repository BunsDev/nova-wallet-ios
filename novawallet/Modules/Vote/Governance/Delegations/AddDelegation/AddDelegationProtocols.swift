import RobinHood
import SoraFoundation

protocol AddDelegationViewProtocol: ControllerBackedProtocol {
    func didReceive(delegateViewModels: [GovernanceDelegateTableViewCell.Model])
    func didReceive(filter: GovernanceDelegatesFilter)
    func didReceive(order: GovernanceDelegatesOrder)
    func didChangeBannerState(isHidden: Bool, animated: Bool)
    func didCompleteListConfiguration()
}

protocol AddDelegationPresenterProtocol: AnyObject {
    func setup()
    func selectDelegate(_ viewModel: GovernanceDelegateTableViewCell.Model)
    func closeBanner()
    func showAddDelegateInformation()
    func showSortOptions()
    func showFilters()
}

protocol AddDelegationInteractorInputProtocol: AnyObject {
    func setup()
    func remakeSubscriptions()
    func refreshDelegates()
    func saveCloseBanner()
}

protocol AddDelegationInteractorOutputProtocol: AnyObject {
    func didReceiveDelegates(_ delegates: [GovernanceDelegateLocal])
    func didReceiveShouldDisplayBanner(_ isHidden: Bool)
    func didReceiveError(_ error: AddDelegationInteractorError)
}

protocol AddDelegationWireframeProtocol: AlertPresentable, ErrorPresentable, CommonRetryable, WebPresentable {
    func showPicker(
        from view: AddDelegationViewProtocol?,
        title: LocalizableResource<String>?,
        items: [LocalizableResource<SelectableTitleTableViewCell.Model>],
        selectedIndex: Int,
        delegate: ModalPickerViewControllerDelegate
    )

    func showInfo(from view: AddDelegationViewProtocol?, delegate: GovernanceDelegateLocal)
}
