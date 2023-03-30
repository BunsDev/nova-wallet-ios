import BigInt

enum Caip2 {}

extension Caip2 {
    struct ChainId: Hashable {
        let namespace: String
        let reference: String

        init(raw: String) throws {
            let chain = raw.split(by: .colon)
            guard chain.count == 2 else {
                throw ParseError.invalidInputString
            }
            let parsedNamespace = chain[0]
            let parsedReference = chain[1]

            if let namespaceCheckError = parsedNamespace.checkLength(min: 3, max: 8) {
                throw ParseError.invalidNamespace(namespaceCheckError)
            }
            if let referenceCheckError = parsedNamespace.checkLength(min: 1, max: 32) {
                throw ParseError.invalidReference(referenceCheckError)
            }

            namespace = parsedNamespace
            reference = parsedReference
        }
    }
}

extension Caip2 {
    enum RegisteredChain: Equatable {
        case polkadot(genesisHash: String)
        case eip155(id: BigUInt)

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case let (.polkadot(hash), .polkadot(otherHash)):
                return hash == otherHash
            case let (.eip155(id), .eip155(otherId)):
                return id == otherId
            default:
                return false
            }
        }
    }
}

extension Caip2.ChainId {
    var knownChain: Caip2.RegisteredChain? {
        switch namespace {
        case "eip155":
            guard let id = BigUInt(reference) else {
                return nil
            }
            return .eip155(id: id)
        case "polkadot":
            return .polkadot(genesisHash: reference)
        default:
            return nil
        }
    }
}

extension Caip2.ChainId {
    func match(_ identifier: String) -> Bool {
        switch knownChain {
        case let .polkadot(chainId):
            return identifier.hasPrefix(chainId)
        case let .eip155(id):
            return identifier.caseInsensitiveCompare("eip155:\(id)") == .orderedSame
        default:
            return false
        }
    }
}
