import UIKit
import CDMarkdownKit
import RobinHood

protocol MarkdownViewContainerDelegate: AnyObject {
    func markdownView(_ view: MarkdownViewContainer, asksHandle url: URL)
}

final class MarkdownViewContainer: UIView, AnyCancellableCleaning {
    private var textView: UITextView?
    private var model: MarkupAttributedText?
    let preferredWidth: CGFloat

    override var intrinsicContentSize: CGSize {
        CGSize(width: preferredWidth, height: model?.preferredSize.height ?? 0)
    }

    let operationQueue: OperationQueue

    private let operationFactory: MarkupParsingOperationFactoryProtocol

    private var operation: CancellableCall?

    weak var delegate: MarkdownViewContainerDelegate?

    init(
        preferredWidth: CGFloat,
        maxTextLength: Int? = nil,
        operationQueue: OperationQueue = OperationQueue()
    ) {
        self.preferredWidth = preferredWidth
        let markdownParsingOperationFactory = MarkdownParsingOperationFactory(maxSize: maxTextLength)
        let htmlParsingOperationFactory = HtmlParsingOperationFactory(maxSize: maxTextLength)

        operationFactory = MarkupParsingOperationFactory(
            markdownParsingOperationFactory: markdownParsingOperationFactory,
            htmlParsingOperationFactory: htmlParsingOperationFactory,
            operationQueue: operationQueue
        )

        self.operationQueue = operationQueue

        super.init(frame: .zero)
    }

    deinit {
        clear(cancellable: &operation)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func clearTextView() {
        textView?.removeFromSuperview()
        textView = nil
    }

    func setupTextView(for size: CGSize, text: NSAttributedString) {
        clearTextView()

        let textContainer = NSTextContainer(size: size)
        let layoutManager = CDMarkdownLayoutManager()
        layoutManager.roundAllCorners = true
        layoutManager.addTextContainer(textContainer)
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)

        let textView = UITextView(
            frame: .init(origin: .zero, size: size),
            textContainer: textContainer
        )

        textView.delegate = self
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.isSelectable = true
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0

        textView.backgroundColor = .clear

        addSubview(textView)

        textView.snp.makeConstraints { make in
            make.leading.trailing.top.bottom.equalToSuperview()
        }

        textView.attributedText = text

        self.textView = textView
    }

    private func bind(model: MarkupAttributedText) {
        self.model = model

        setupTextView(for: model.preferredSize, text: model.attributedString)

        invalidateIntrinsicContentSize()
    }
}

extension MarkdownViewContainer {
    func load(from string: String, completion: ((MarkupAttributedText?) -> Void)?) {
        guard model?.originalString != string else {
            completion?(model)
            return
        }

        model = nil

        clear(cancellable: &operation)
        clearTextView()

        let wrapper = operationFactory.createParseOperation(for: string, preferredWidth: preferredWidth)

        wrapper.targetOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                guard self?.operation === wrapper else {
                    completion?(nil)
                    return
                }

                do {
                    guard let model = try wrapper.targetOperation.extractNoCancellableResultData() else {
                        return
                    }
                    self?.bind(model: model)
                    completion?(model)
                } catch {
                    completion?(nil)
                }
            }
        }

        operation = wrapper

        operationQueue.addOperations(wrapper.allOperations, waitUntilFinished: false)
    }
}

extension MarkdownViewContainer: UITextViewDelegate {
    func textView(
        _: UITextView,
        shouldInteractWith URL: URL,
        in _: NSRange,
        interaction _: UITextItemInteraction
    ) -> Bool {
        delegate?.markdownView(self, asksHandle: URL)
        return false
    }
}
