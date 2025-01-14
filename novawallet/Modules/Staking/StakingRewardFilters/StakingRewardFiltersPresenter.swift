import Foundation

final class StakingRewardFiltersPresenter {
    weak var view: StakingRewardFiltersViewProtocol?
    weak var delegate: StakingRewardFiltersDelegate?

    let period: StakingRewardFiltersPeriod
    let wireframe: StakingRewardFiltersWireframeProtocol

    init(
        initialState: StakingRewardFiltersPeriod,
        delegate: StakingRewardFiltersDelegate,
        wireframe: StakingRewardFiltersWireframeProtocol
    ) {
        period = initialState
        self.delegate = delegate
        self.wireframe = wireframe
    }
}

extension StakingRewardFiltersPresenter: StakingRewardFiltersPresenterProtocol {
    func setup() {
        view?.didReceive(viewModel: period)
    }

    func save(_ period: StakingRewardFiltersPeriod) {
        delegate?.stackingRewardFilter(didSelectFilter: period)
        wireframe.close(view: view)
    }
}
