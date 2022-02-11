import UIKit
import WebKit

final class DAppBrowserViewController: UIViewController, ViewHolder {
    typealias RootViewType = DAppBrowserViewLayout

    let presenter: DAppBrowserPresenterProtocol

    private var viewModel: DAppBrowserModel?

    private var urlObservation: NSKeyValueObservation?
    private var goBackObservation: NSKeyValueObservation?
    private var goForwardObservation: NSKeyValueObservation?

    private var scriptMessageHandler: DAppBrowserScriptHandler?

    init(presenter: DAppBrowserPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        urlObservation?.invalidate()
    }

    override func loadView() {
        view = DAppBrowserViewLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configure()

        presenter.setup()
    }

    private func configure() {
        navigationItem.titleView = rootView.urlBar

        navigationItem.leftItemsSupplementBackButton = false
        navigationItem.leftBarButtonItem = rootView.closeBarItem

        rootView.closeBarItem.target = self
        rootView.closeBarItem.action = #selector(actionClose)

        rootView.webView.uiDelegate = self
        rootView.webView.allowsBackForwardNavigationGestures = true

        urlObservation = rootView.webView.observe(\.url, options: [.initial, .new]) { [weak self] _, change in
            guard let newValue = change.newValue, let url = newValue else {
                return
            }

            self?.didChangeUrl(url)
        }

        goBackObservation = rootView.webView.observe(
            \.canGoBack,
            options: [.initial, .new]
        ) { [weak self] _, change in
            guard let newValue = change.newValue else {
                return
            }

            self?.didChangeGoBack(newValue)
        }

        goForwardObservation = rootView.webView.observe(
            \.canGoForward,
            options: [.initial, .new]
        ) { [weak self] _, change in
            guard let newValue = change.newValue else {
                return
            }

            self?.didChangeGoForward(newValue)
        }

        rootView.goBackBarItem.target = self
        rootView.goBackBarItem.action = #selector(actionGoBack)

        rootView.goForwardBarItem.target = self
        rootView.goForwardBarItem.action = #selector(actionGoForward)

        rootView.refreshBarItem.target = self
        rootView.refreshBarItem.action = #selector(actionRefresh)

        rootView.urlBar.addTarget(self, action: #selector(actionSearch), for: .touchUpInside)

        scriptMessageHandler = DAppBrowserScriptHandler(
            contentController: rootView.webView.configuration.userContentController,
            delegate: self
        )
    }

    private func didChangeUrl(_ newUrl: URL) {
        rootView.urlLabel.text = newUrl.host

        if newUrl.isTLSScheme {
            rootView.securityImageView.image = R.image.iconBrowserSecurity()
        } else {
            rootView.securityImageView.image = nil
        }

        rootView.urlBar.setNeedsLayout()
    }

    private func didChangeGoBack(_ newValue: Bool) {
        rootView.goBackBarItem.isEnabled = newValue
    }

    private func didChangeGoForward(_: Bool) {
        rootView.goForwardBarItem.isEnabled = rootView.webView.canGoForward
    }

    @objc private func actionGoBack() {
        rootView.webView.goBack()
    }

    @objc private func actionGoForward() {
        rootView.webView.goForward()
    }

    @objc private func actionFavorite() {}

    @objc private func actionRefresh() {
        rootView.webView.reload()
    }

    @objc private func actionSearch() {
        presenter.activateSearch(with: rootView.webView.url?.absoluteString)
    }

    @objc private func actionClose() {
        presenter.close()
    }
}

extension DAppBrowserViewController: DAppBrowserScriptHandlerDelegate {
    func browserScriptHandler(_: DAppBrowserScriptHandler, didReceive message: WKScriptMessage) {
        presenter.process(message: message.body)
    }
}

extension DAppBrowserViewController: DAppBrowserViewProtocol {
    func didReceive(viewModel: DAppBrowserModel) {
        scriptMessageHandler?.bind(viewModel: viewModel)

        rootView.urlLabel.text = viewModel.url.host

        if viewModel.url.isTLSScheme {
            rootView.securityImageView.image = R.image.iconBrowserSecurity()
        } else {
            rootView.securityImageView.image = nil
        }

        rootView.urlBar.setNeedsLayout()

        rootView.goBackBarItem.isEnabled = false
        rootView.goForwardBarItem.isEnabled = false

        let request = URLRequest(url: viewModel.url)
        rootView.webView.load(request)
    }

    func didReceive(response: PolkadotExtensionResponse) {
        rootView.webView.evaluateJavaScript(response.content)
    }
}

extension DAppBrowserViewController: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        createWebViewWith _: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures _: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }

        return nil
    }
}