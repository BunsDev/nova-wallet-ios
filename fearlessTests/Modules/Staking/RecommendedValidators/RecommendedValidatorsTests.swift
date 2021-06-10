import XCTest
@testable import fearless
import Cuckoo
import RobinHood

class RecommendedValidatorsTests: XCTestCase {
    func testSetupAndOptionSelect() {
        // given

        let view = MockRecommendedValidatorsViewProtocol()
        let wireframe = MockRecommendedValidatorsWireframeProtocol()
        let operationFactory = MockValidatorOperationFactoryProtocol()

        let recommendationsComposer = RecommendationsComposer(
            resultSize: StakingConstants.maxTargets,
            clusterSizeLimit: StakingConstants.targetsClusterLimit
        )

        let presenter = RecommendedValidatorsPresenter(
            recommendationsComposer: recommendationsComposer
        )

        let interactor = RecommendedValidatorsInteractor(operationFactory: operationFactory,
                                                         operationManager: OperationManager())

        presenter.view = view
        presenter.wireframe = wireframe
        presenter.interactor = interactor
        interactor.presenter = presenter

        // when

        stub(operationFactory) { stub in
            when(stub).allElectedOperation().then { _ in
                CompoundOperationWrapper.createWithResult(WestendStub.allValidators)
            }
        }

        let setupExpectation = XCTestExpectation()

        stub(view) { stub in
            when(stub).didReceive(viewModel: any()).then { _ in
                setupExpectation.fulfill()
            }
        }

        let recommended = WestendStub.recommendedValidators
        let all = WestendStub.allValidators

        stub(wireframe) { stub in
            when(stub).proceedToCustomList(from: any(), validators: any()).then { (_, validators) in
                XCTAssertEqual(all, validators)
            }

            when(stub).proceedToRecommendedList(from: any(), validators: any(), maxTargets: any()).then { (_, targets, _) in
                XCTAssertEqual(Set(recommended.map({ $0.address })),
                               Set(targets.map({ $0.address })))
            }
        }

        presenter.setup()

        // then

        wait(for: [setupExpectation], timeout: Constants.defaultExpectationDuration)

        presenter.selectRecommendedValidators()
        presenter.selectCustomValidators()

        verify(wireframe, times(1)).proceedToCustomList(from: any(), validators: any())
        verify(wireframe, times(1)).proceedToRecommendedList(from: any(), validators: any(), maxTargets: any())
    }
}
