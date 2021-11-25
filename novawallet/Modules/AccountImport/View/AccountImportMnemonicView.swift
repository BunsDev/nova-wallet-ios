import UIKit
import SoraUI
import SoraFoundation

protocol AccountImportMnemonicViewDelegate: AnyObject {
    func accountImportMnemonicViewDidProceed(_ view: AccountImportMnemonicView)
}

final class AccountImportMnemonicView: AccountImportBaseView {
    weak var delegate: AccountImportMnemonicViewDelegate?

    let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        return view
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = R.color.colorWhite()
        label.font = .h2Title
        label.numberOfLines = 0
        return label
    }()

    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = R.color.colorLightGray()
        label.font = .p1Paragraph
        label.numberOfLines = 0
        return label
    }()

    let usernameBackgroundView: RoundedView = UIFactory.default.createRoundedBackgroundView()

    let usernameTextField: AnimatedTextField = UIFactory.default.createAnimatedTextField()

    let usernameHintLabel: UILabel = {
        let label = UILabel()
        label.font = .p2Paragraph
        label.textColor = R.color.colorLightGray()
        label.numberOfLines = 0
        return label
    }()

    let mnemonicBackgroundView: RoundedView = UIFactory.default.createRoundedBackgroundView()

    let mnemonicTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = R.color.colorLightGray()
        label.font = .p2Paragraph
        return label
    }()

    let mnemonicTextView: UITextView = {
        let view = UITextView()
        view.font = .p1Paragraph
        view.textColor = R.color.colorWhite()
        view.tintColor = R.color.colorWhite()
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()

    let hintLabel: UILabel = {
        let label = UILabel()
        label.textColor = R.color.colorLightGray()
        label.font = .p2Paragraph
        label.numberOfLines = 0
        return label
    }()

    let proceedButton: TriangularedButton = {
        let button = TriangularedButton()
        button.applyDefaultStyle()
        return button
    }()

    private(set) var sourceViewModel: InputViewModelProtocol?
    private(set) var usernameViewModel: InputViewModelProtocol?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .clear

        setupLayout()
        setupHandlers()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindSource(viewModel: InputViewModelProtocol) {
        sourceViewModel = viewModel
        mnemonicTextView.text = viewModel.inputHandler.value

        updateProceedButton()
    }

    func bindUsername(viewModel: InputViewModelProtocol?) {
        usernameViewModel = viewModel
        usernameTextField.text = viewModel?.inputHandler.value

        updateProceedButton()
    }

    override func setupLocalization() {
        titleLabel.text = "Enter the words in the right order"
        subtitleLabel.text = "Write words separately with one space, no commas or other signs."
        mnemonicTitleLabel.text = "Mnemonic Passphrase"
        hintLabel.text = "Typically 12-word phrase (but may be 15, 18, 21 or 24)"

        usernameTextField.title = R.string.localizable.walletUsernameSetupChooseTitle(
            preferredLanguages: locale?.rLanguages
        )

        usernameHintLabel.text = R.string.localizable.walletNicknameCreateCaption(
            preferredLanguages: locale?.rLanguages
        )

        updateProceedButton()
    }

    override func updateOnKeyboardBottomInsetChange(_ newInset: CGFloat) {
        let scrollViewOffset = bounds.height - scrollView.frame.maxY

        var contentInsets = scrollView.contentInset
        contentInsets.bottom = max(0.0, newInset - scrollViewOffset)
        scrollView.contentInset = contentInsets

        if contentInsets.bottom > 0.0 {
            let targetView: UIView?

            if mnemonicTextView.isFirstResponder {
                targetView = mnemonicBackgroundView
            } else if usernameTextField.isFirstResponder {
                targetView = usernameBackgroundView
            } else {
                targetView = nil
            }

            if let firstResponderView = targetView {
                let fieldFrame = scrollView.convert(
                    firstResponderView.frame,
                    from: firstResponderView.superview
                )

                scrollView.scrollRectToVisible(fieldFrame, animated: true)
            }
        }
    }

    override func updateOnAppear() {
        mnemonicTextView.becomeFirstResponder()
    }

    private func setupHandlers() {
        proceedButton.addTarget(self, action: #selector(actionProceed), for: .touchUpInside)

        mnemonicTextView.returnKeyType = .done
        mnemonicTextView.textContentType = .none
        mnemonicTextView.autocapitalizationType = .none
        mnemonicTextView.autocorrectionType = .no
        mnemonicTextView.spellCheckingType = .no
        mnemonicTextView.delegate = self

        usernameTextField.textField.returnKeyType = .done
        usernameTextField.textField.textContentType = .nickname
        usernameTextField.textField.autocapitalizationType = .sentences
        usernameTextField.textField.autocorrectionType = .no
        usernameTextField.textField.spellCheckingType = .no

        usernameTextField.delegate = self

        usernameTextField.addTarget(self, action: #selector(actionTextFieldChanged(_:)), for: .editingChanged)
    }

    // swiftlint:disable function_body_length
    private func setupLayout() {
        addSubview(proceedButton)
        proceedButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.bottom.equalTo(safeAreaLayoutGuide).inset(UIConstants.actionBottomInset)
            make.height.equalTo(UIConstants.actionHeight)
        }

        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.bottom.equalTo(proceedButton.snp.top).offset(-16.0)
        }

        let contentView = UIView()
        contentView.backgroundColor = .clear
        scrollView.addSubview(contentView)

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(self)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.top.equalToSuperview().inset(UIConstants.verticalTitleInset)
        }

        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.top.equalTo(titleLabel.snp.bottom).offset(12.0)
        }

        contentView.addSubview(mnemonicBackgroundView)

        mnemonicBackgroundView.addSubview(mnemonicTitleLabel)
        mnemonicTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8.0)
            make.leading.trailing.equalToSuperview().inset(16.0)
        }

        mnemonicBackgroundView.addSubview(mnemonicTextView)
        mnemonicTextView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(20)
            make.leading.trailing.equalToSuperview().inset(12.0)
            make.height.greaterThanOrEqualTo(72.0)
        }

        mnemonicBackgroundView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24.0)
            make.height.equalTo(mnemonicTextView).offset(32.0)
        }

        contentView.addSubview(hintLabel)
        hintLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.top.equalTo(mnemonicBackgroundView.snp.bottom).offset(12.0)
        }

        contentView.addSubview(usernameBackgroundView)
        usernameBackgroundView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.top.equalTo(hintLabel.snp.bottom).offset(16.0)
            make.height.equalTo(UIConstants.triangularedViewHeight)
        }

        usernameBackgroundView.addSubview(usernameTextField)
        usernameTextField.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.addSubview(usernameHintLabel)
        usernameHintLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(UIConstants.horizontalInset)
            make.top.equalTo(usernameBackgroundView.snp.bottom).offset(12.0)
            make.bottom.equalTo(contentView)
        }
    }

    private func updateProceedButton() {
        if let viewModel = sourceViewModel, viewModel.inputHandler.required, mnemonicTextView.text.isEmpty {
            proceedButton.applyDisabledStyle()
            proceedButton.imageWithTitleView?.title = "Enter the words..."
        } else if let viewModel = usernameViewModel, viewModel.inputHandler.required,
                  (usernameTextField.text ?? "").isEmpty {
            proceedButton.applyDisabledStyle()
            proceedButton.imageWithTitleView?.title = "Enter wallet name..."
        } else {
            proceedButton.applyEnabledStyle()
            proceedButton.imageWithTitleView?.title = R.string.localizable.commonContinue(
                preferredLanguages: locale?.rLanguages
            )
        }
    }

    @objc private func actionProceed() {
        delegate?.accountImportMnemonicViewDidProceed(self)
    }

    @objc private func actionTextFieldChanged(_ sender: UITextField) {
        if usernameViewModel?.inputHandler.value != sender.text {
            sender.text = usernameViewModel?.inputHandler.value
        }

        updateProceedButton()
    }
}

extension AccountImportMnemonicView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView.text != sourceViewModel?.inputHandler.value {
            textView.text = sourceViewModel?.inputHandler.value
        }

        updateProceedButton()
    }

    func textView(
        _ textView: UITextView,
        shouldChangeTextIn range: NSRange,
        replacementText text: String
    ) -> Bool {
        if text == String.returnKey {
            textView.resignFirstResponder()
            return false
        }

        guard let model = sourceViewModel else {
            return false
        }

        let shouldApply = model.inputHandler.didReceiveReplacement(text, for: range)

        if !shouldApply, textView.text != model.inputHandler.value {
            textView.text = model.inputHandler.value
        }

        return shouldApply
    }
}

extension AccountImportMnemonicView: AnimatedTextFieldDelegate {
    func animatedTextFieldShouldReturn(_ textField: AnimatedTextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

    func animatedTextField(
        _ textField: AnimatedTextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let currentViewModel = usernameViewModel else {
            return true
        }

        let shouldApply = currentViewModel.inputHandler.didReceiveReplacement(string, for: range)

        if !shouldApply, textField.text != currentViewModel.inputHandler.value {
            textField.text = currentViewModel.inputHandler.value
        }

        return shouldApply
    }
}
