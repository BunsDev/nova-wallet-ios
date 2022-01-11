import UIKit
import RobinHood

enum DAppBrowserInteractorError: Error {
    case scriptFileMissing
    case invalidUrl
    case unexpectedMessageType
    case specVersionMismatch
}

final class DAppBrowserInteractor {
    static let subscriptionName = "_nova_"

    weak var presenter: DAppBrowserInteractorOutputProtocol!

    private(set) var userQuery: DAppUserQuery
    let dataSource: DAppBrowserStateDataSource
    let logger: LoggerProtocol?

    private(set) var messageQueue: [PolkadotExtensionMessage] = []
    private(set) var state: DAppBrowserStateProtocol?

    init(
        userQuery: DAppUserQuery,
        wallet: MetaAccountModel,
        chainRegistry: ChainRegistryProtocol,
        operationQueue: OperationQueue,
        logger: LoggerProtocol? = nil
    ) {
        self.userQuery = userQuery
        dataSource = DAppBrowserStateDataSource(
            wallet: wallet,
            chainRegistry: chainRegistry,
            operationQueue: operationQueue
        )
        self.logger = logger
    }

    private func subscribeChainRegistry() {
        dataSource.chainRegistry.chainsSubscribe(self, runningInQueue: .main) { [weak self] changes in
            for change in changes {
                switch change {
                case let .insert(newItem):
                    self?.dataSource.set(chain: newItem, for: newItem.identifier)
                case let .update(newItem):
                    self?.dataSource.set(chain: newItem, for: newItem.identifier)
                case let .delete(deletedIdentifier):
                    self?.dataSource.set(chain: nil, for: deletedIdentifier)
                }
            }

            self?.completeSetupIfNeeded()
        }
    }

    private func completeSetupIfNeeded() {
        if state == nil, !dataSource.chainStore.isEmpty {
            state = DAppBrowserWaitingAuthState(stateMachine: self)
            provideModel()
        }
    }

    private func createBridgeScriptOperation() -> BaseOperation<DAppBrowserScript> {
        ClosureOperation<DAppBrowserScript> {
            guard let url = R.file.nova_minJs.url() else {
                throw DAppBrowserInteractorError.scriptFileMissing
            }

            let content = try String(contentsOf: url)

            return DAppBrowserScript(content: content, insertionPoint: .atDocStart)
        }
    }

    private func createSubscriptionScript() -> DAppBrowserScript {
        let content =
            """
            window.addEventListener("message", ({ data, source }) => {
              // only allow messages from our window, by the loader
              if (source !== window) {
                return;
              }

              if (data.origin === "dapp-request") {
                window.webkit.messageHandlers.\(Self.subscriptionName).postMessage(data);
              }
            });
            """

        let script = DAppBrowserScript(content: content, insertionPoint: .atDocEnd)
        return script
    }

    func provideModel() {
        let maybeUrl: URL? = {
            switch userQuery {
            case let .url(url):
                return url
            case let .search(query):
                if NSPredicate.urlPredicate.evaluate(with: query), let inputUrl = URL(string: query) {
                    return inputUrl
                } else {
                    let querySet = CharacterSet.urlQueryAllowed
                    guard let searchQuery = query.addingPercentEncoding(withAllowedCharacters: querySet) else {
                        return nil
                    }

                    return URL(string: "https://duckduckgo.com/?q=\(searchQuery)")
                }
            }
        }()

        guard let url = maybeUrl else {
            presenter.didReceive(error: DAppBrowserInteractorError.invalidUrl)
            return
        }

        let bridgeOperation = createBridgeScriptOperation()
        let subscriptionScript = createSubscriptionScript()

        bridgeOperation.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                do {
                    let bridgeScript = try bridgeOperation.extractNoCancellableResultData()

                    let model = DAppBrowserModel(
                        url: url,
                        subscriptionName: Self.subscriptionName,
                        scripts: [bridgeScript, subscriptionScript]
                    )

                    self?.presenter.didReceiveDApp(model: model)
                } catch {
                    self?.presenter.didReceive(error: error)
                }
            }
        }

        dataSource.operationQueue.addOperation(bridgeOperation)
    }

    private func processMessageIfNeeded() {
        guard let state = state, state.canHandleMessage(), let message = messageQueue.first else {
            return
        }

        messageQueue.removeFirst()

        state.handle(message: message, dataSource: dataSource)
    }
}

extension DAppBrowserInteractor: DAppBrowserInteractorInputProtocol {
    func setup() {
        subscribeChainRegistry()
    }

    func process(message: Any) {
        guard let dict = message as? NSDictionary else {
            presenter.didReceive(error: DAppBrowserInteractorError.unexpectedMessageType)
            return
        }

        do {
            logger?.info("Did receive message: \(dict)")

            let parsedMessage = try dict.map(to: PolkadotExtensionMessage.self)
            messageQueue.append(parsedMessage)

            processMessageIfNeeded()
        } catch {
            presenter.didReceive(error: error)
        }
    }

    func processConfirmation(response: DAppOperationResponse) {
        state?.handleOperation(response: response, dataSource: dataSource)
    }

    func process(newQuery: String) {
        userQuery = .search(newQuery)

        state?.stateMachine = nil
        state = nil
        completeSetupIfNeeded()
    }

    func processAuth(response: DAppAuthResponse) {
        state?.handleAuth(response: response, dataSource: dataSource)
    }
}

extension DAppBrowserInteractor: DAppBrowserStateMachineProtocol {
    func emit(nextState: DAppBrowserStateProtocol) {
        state = nextState
    }

    func emit(response: PolkadotExtensionResponse, nextState: DAppBrowserStateProtocol) {
        state = nextState

        presenter.didReceive(response: response)

        nextState.setup(with: dataSource)
    }

    func emit(authRequest: DAppAuthRequest, nextState: DAppBrowserStateProtocol) {
        state = nextState

        presenter.didReceiveAuth(request: authRequest)

        nextState.setup(with: dataSource)
    }

    func emit(signingRequest: DAppOperationRequest, nextState: DAppBrowserStateProtocol) {
        state = nextState

        presenter.didReceiveConfirmation(request: signingRequest)

        nextState.setup(with: dataSource)
    }

    func emit(error: Error, nextState: DAppBrowserStateProtocol) {
        state = nextState

        presenter.didReceive(error: error)

        nextState.setup(with: dataSource)
    }

    func popMessage() {
        processMessageIfNeeded()
    }
}
