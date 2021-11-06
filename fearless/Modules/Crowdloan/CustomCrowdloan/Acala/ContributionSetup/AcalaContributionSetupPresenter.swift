import Foundation
import BigInt

final class AcalaContributionSetupPresenter: CrowdloanContributionSetupPresenter {
    var acalaService: AcalaBonusService? {
        bonusService as? AcalaBonusService
    }

    private var minimumContributionLcDot: BigUInt?

    override func provideBonusViewModel() {
        let inputAmount = inputResult?.absoluteValue(from: balanceMinusFee) ?? 0
        let viewModel: String? = {
            if let displayInfo = displayInfo, let flow = displayInfo.customFlow, flow.supportsAdditionalBonus {
                let bonusRate = bonusService?.referralCode != nil ? bonusService?.bonusRate : nil
                return contributionViewModelFactory.createAdditionalBonusViewModel(
                    inputAmount: inputAmount,
                    displayInfo: displayInfo,
                    bonusRate: bonusRate,
                    locale: selectedLocale
                )
            } else {
                return nil
            }
        }()

        view?.didReceiveBonus(viewModel: viewModel)
    }
}

extension AcalaContributionSetupPresenter: AcalaContributionSetupPresenterProtocol {
    var selectedContributionMethod: AcalaContributionMethod {
        acalaService?.selectedContributionMethod ?? .direct
    }

    func selectContributionMethod(_ method: AcalaContributionMethod) {
        acalaService?.selectedContributionMethod = method
        switch method {
        case .direct:
            if let minimumContribution = minimumContributionLcDot {
                self.minimumContribution = minimumContribution
            }
        case .liquid:
            minimumContributionLcDot = minimumContribution
            minimumContribution = BigUInt(1e+10)
        }
    }
}