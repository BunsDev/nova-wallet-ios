import UIKit

final class AnalyticsViewController: UIViewController, ViewHolder {
    typealias RootViewType = AnalyticsViewLayout

    let presenter: AnalyticsPresenterProtocol

    init(presenter: AnalyticsPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = AnalyticsViewLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        presenter.setup()
        rootView.segmentedControl.configure()
        rootView.segmentedControl.titles = ["Rewards", "Stake", "Validators"]

        rootView.periodView.configure(periods: AnalyticsPeriod.allCases)
        rootView.periodView.delegate = self

        rootView.receivedSummaryView.configure(
            with: .init(
                title: "Received",
                tokenAmount: "0.02931 KSM",
                usdAmount: "$11.72",
                indicatorColor: R.color.colorGray()
            )
        )

        rootView.payableSummaryView.configure(
            with: .init(
                title: "Payable",
                tokenAmount: "0.00875 KSM",
                usdAmount: "$3.5",
                indicatorColor: R.color.colorAccent()
            )
        )
    }
}

extension AnalyticsViewController: AnalyticsViewProtocol {}

extension AnalyticsViewController: AnalyticsPeriodViewDelegate {
    func didSelect(period: AnalyticsPeriod) {
        print(period)
    }
}
