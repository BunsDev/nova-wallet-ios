import Foundation

final class RampProvider: PurchaseProviderProtocol {
    static let pubToken = "3quzr4e6wdyccndec8jzjebzar5kxxzfy2f3us5k"
    static let baseUrlString = "https://buy.ramp.network/"

    private var appName: String?
    private var logoUrl: URL?
    private var callbackUrl: URL?

    func with(appName: String) -> Self {
        self.appName = appName
        return self
    }

    func with(logoUrl: URL) -> Self {
        self.logoUrl = logoUrl
        return self
    }

    func with(callbackUrl: URL) -> Self {
        self.callbackUrl = callbackUrl
        return self
    }

    func buildPurchaseActions(
        for chainAsset: ChainAsset,
        accountId: AccountId
    ) -> [PurchaseAction] {
        guard
            chainAsset.asset.buyProviders?.ramp != nil,
            let address = try? accountId.toAddress(using: chainAsset.chain.chainFormat) else {
            return []
        }

        let optionUrl = buildURLForToken(chainAsset.asset.symbol, address: address)

        if let url = optionUrl {
            let action = PurchaseAction(title: "Ramp", url: url, icon: R.image.iconRamp()!)
            return [action]
        } else {
            return []
        }
    }

    private func buildURLForToken(_ token: String, address: String) -> URL? {
        var components = URLComponents(string: Self.baseUrlString)

        var queryItems = [
            URLQueryItem(name: "swapAsset", value: token),
            URLQueryItem(name: "userAddress", value: address),
            URLQueryItem(name: "hostApiKey", value: Self.pubToken),
            URLQueryItem(name: "variant", value: "hosted-mobile")
        ]

        if let callbackUrl = callbackUrl?.absoluteString {
            queryItems.append(URLQueryItem(name: "finalUrl", value: callbackUrl))
        }

        if let appName = appName {
            queryItems.append(URLQueryItem(name: "hostAppName", value: appName))
        }

        if let logoUrl = logoUrl?.absoluteString
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            queryItems.append(URLQueryItem(name: "hostLogoUrl", value: logoUrl))
        }

        components?.queryItems = queryItems

        return components?.url
    }
}
