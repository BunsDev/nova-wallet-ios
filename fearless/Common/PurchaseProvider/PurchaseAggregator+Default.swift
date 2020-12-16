import Foundation

extension PurchaseAggregator {
    static func defaultAggregator() -> PurchaseAggregator {
        let config: ApplicationConfigProtocol = ApplicationConfig.shared
        let purchaseProviders: [PurchaseProviderProtocol] = [
            RampProvider()
        ]
        return PurchaseAggregator(providers: purchaseProviders)
            .with(appName: config.appName)
            .with(logoUrl: config.logoUrl)
    }
}
