import XCTest
@testable import novawallet
import Cuckoo
import RobinHood

class SelectValidatorsStartTests: XCTestCase {
    func testSetupValidators() throws {
        let allValidators = WestendStub.allValidators
        let recomendedValidators = WestendStub.recommendedValidators

        try performTest(
            for: nil,
            allValidators: allValidators,
            expectedRecommendedValidators: recomendedValidators,
            expectedViewModel: SelectValidatorsStartViewModel(
                selectedCount: 0,
                totalCount: 16
            ),
            expectedCustomValidators: allValidators.map { $0.toSelected(for: nil) }
        )
    }

    func testChangeValidators() throws {
        let allValidators = WestendStub.allValidators
        let recomendedValidators = WestendStub.recommendedValidators

        try performTest(
            for: recomendedValidators.map { $0.toSelected(for: nil) },
            allValidators: allValidators,
            expectedRecommendedValidators: recomendedValidators,
            expectedViewModel: SelectValidatorsStartViewModel(
                selectedCount: recomendedValidators.count,
                totalCount: 16
            ),
            expectedCustomValidators: allValidators.map { $0.toSelected(for: nil) }
        )
    }

    private func performTest(
        for selectedTargets: [SelectedValidatorInfo]?,
        allValidators: [ElectedValidatorInfo],
        expectedRecommendedValidators: [ElectedValidatorInfo],
        expectedViewModel: SelectValidatorsStartViewModel,
        expectedCustomValidators: [SelectedValidatorInfo]
    ) throws {
        // given

        let view = MockSelectValidatorsStartViewProtocol()
        let wireframe = MockSelectValidatorsStartWireframeProtocol()
        let operationFactory = MockValidatorOperationFactoryProtocol()

        let runtimeService = try RuntimeCodingServiceStub.createWestendService()

        let interactor = SelectValidatorsStartInteractor(
            runtimeService: runtimeService,
            operationFactory: operationFactory,
            operationManager: OperationManager(),
            preferredValidators: []
        )

        let presenter = SelectValidatorsStartPresenter(
            interactor: interactor,
            wireframe: wireframe,
            existingStashAddress: nil,
            initialTargets: selectedTargets,
            applicationConfig: ApplicationConfig.shared
        )

        presenter.view = view
        interactor.presenter = presenter

        // when

        stub(operationFactory) { stub in
            when(stub).allPreferred(for: any()).then { _ in
                CompoundOperationWrapper.createWithResult(.init(electedValidators: allValidators, preferredValidators: []))
            }
        }

        let setupExpectation = XCTestExpectation()

        stub(view) { stub in
            when(stub).didReceive(viewModel: any()).then { viewModel in
                XCTAssertEqual(viewModel, expectedViewModel)
                setupExpectation.fulfill()
            }
        }

        let generator = CustomValidatorListTestDataGenerator.self

        let recommended = generator
            .createSelectedValidators(from: expectedRecommendedValidators)

        stub(wireframe) { stub in
            when(stub).proceedToCustomList(
                from: any(),
                selectionValidatorGroups: any(),
                selectedValidatorList: any(),
                validatorsSelectionParams: any()).then { (_, selectionValidatorGroups, _ , _) in
                    XCTAssertEqual(
                        expectedCustomValidators.sorted {
                            $0.address.lexicographicallyPrecedes($1.address)
                        },
                        selectionValidatorGroups.fullValidatorList.distinctAll().sorted {
                            $0.address.lexicographicallyPrecedes($1.address)
                        })
            }

            when(stub).proceedToRecommendedList(from: any(), validatorList: any(), maxTargets: any()).then { (_, targets, _) in
                XCTAssertEqual(Set(recommended.map({ $0.address })),
                               Set(targets.map({ $0.address })))
            }
        }

        presenter.setup()

        // then

        wait(for: [setupExpectation], timeout: 10)

        presenter.selectRecommendedValidators()
        presenter.selectCustomValidators()

        verify(wireframe, times(1)).proceedToCustomList(from: any(), selectionValidatorGroups: any(),  selectedValidatorList: any(), validatorsSelectionParams: any())
        verify(wireframe, times(1)).proceedToRecommendedList(from: any(), validatorList: any(), maxTargets: any())
    }
}
