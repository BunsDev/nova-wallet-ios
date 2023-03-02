import UIKit
import SoraUI

@objc protocol DelegateInfoDelegate {
    func didTapOnDelegateInfo(sender: DelegateInfoView)
}

final class DelegateInfoView: UIView {
    typealias ContentView = IconDetailsGenericView<GenericPairValueView<
        GenericPairValueView<UILabel, GovernanceDelegateTypeView>, GenericPairValueView<UIImageView, UIView>
    >>

    let baseView = ContentView()

    weak var delegate: DelegateInfoDelegate? {
        didSet {
            baseView.isUserInteractionEnabled = delegate != nil
        }
    }

    var id: Int?

    var iconView: UIImageView {
        baseView.imageView
    }

    var nameLabel: UILabel {
        baseView.detailsView.fView.fView
    }

    var typeView: GovernanceDelegateTypeView {
        baseView.detailsView.fView.sView
    }

    var indicatorView: UIImageView {
        baseView.detailsView.sView.fView
    }

    private var loadingImage: ImageViewModelProtocol?

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(baseView)
        baseView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        baseView.addGestureRecognizer(UITapGestureRecognizer(
            target: self,
            action: #selector(didTapOnBaseView)
        ))
        applyStyle()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTapOnBaseView() {
        delegate?.didTapOnDelegateInfo(sender: self)
    }

    private func applyStyle() {
        backgroundColor = .clear

        baseView.spacing = Constants.nameIconSpace
        baseView.mode = .iconDetails
        baseView.iconWidth = Constants.iconSize.width

        baseView.detailsView.fView.spacing = Constants.nameTypeSpace
        baseView.detailsView.fView.sView.iconDetailsView.iconWidth = Constants.typeIconWidth
        baseView.detailsView.fView.makeHorizontal()
        baseView.detailsView.makeHorizontal()
        baseView.detailsView.fView.sView.contentInsets = .init(top: 1, left: 4, bottom: 1, right: 4)
        baseView.detailsView.fView.sView.backgroundView.cornerRadius = 5
        baseView.detailsView.fView.spacing = 4

        nameLabel.numberOfLines = 1
        nameLabel.apply(style: .footnotePrimary)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        indicatorView.image = R.image.iconInfoFilled()?.tinted(with: R.color.colorIconSecondary()!)
        typeView.setContentHuggingPriority(.required, for: .horizontal)
        baseView.detailsView.sView.sView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        baseView.detailsView.sView.sView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        baseView.detailsView.sView.makeHorizontal()
        baseView.detailsView.sView.spacing = 4
    }
}

extension DelegateInfoView {
    struct Model: Equatable {
        let type: GovernanceDelegateTypeView.Model?
        let addressViewModel: DisplayAddressViewModel

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.type == rhs.type && lhs.addressViewModel.address == rhs.addressViewModel.address &&
                lhs.addressViewModel.name == rhs.addressViewModel.name
        }
    }

    func bind(viewModel: Model) {
        bind(type: viewModel.type)

        loadingImage?.cancel(on: iconView)

        if let iconRadius = iconRadius(for: viewModel.type) {
            viewModel.addressViewModel.imageViewModel?.loadImage(
                on: iconView,
                targetSize: Constants.iconSize,
                cornerRadius: iconRadius,
                animated: true
            )
        } else {
            viewModel.addressViewModel.imageViewModel?.loadImage(
                on: iconView,
                targetSize: Constants.iconSize,
                animated: true
            )
        }

        nameLabel.lineBreakMode = viewModel.addressViewModel.lineBreakMode
        nameLabel.text = viewModel.addressViewModel.name ?? viewModel.addressViewModel.address
        loadingImage = viewModel.addressViewModel.imageViewModel
    }

    private func bind(type: GovernanceDelegateTypeView.Model?) {
        guard let type = type else {
            typeView.isHidden = true
            return
        }

        typeView.isHidden = false
        typeView.iconDetailsView.detailsLabel.isHidden = true
        switch type {
        case .individual:
            typeView.iconDetailsView.imageView.image = R.image.iconIndividual()
        case .organization:
            typeView.iconDetailsView.imageView.image = R.image.iconOrganization()
        }
    }

    private func iconRadius(for type: GovernanceDelegateTypeView.Model?) -> CGFloat? {
        switch type {
        case .organization:
            return nil
        case .individual, .none:
            return Constants.iconSize.width / 2
        }
    }
}

extension DelegateInfoView {
    enum Constants {
        static let nameIconSpace: CGFloat = 12
        static let iconSize = CGSize(width: 24, height: 24)
        static let nameTypeSpace: CGFloat = 4
        static let indicatorWidth: CGFloat = 12
        static let typeIconWidth: CGFloat = 21
    }
}
