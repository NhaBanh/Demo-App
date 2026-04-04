import Foundation

enum AppError: LocalizedError {
    case validation(String)
    case persistence(String)
    case network(String)
    case transientNetwork(String)

    var errorDescription: String? {
        switch self {
        case let .validation(message),
             let .persistence(message),
             let .network(message),
             let .transientNetwork(message):
            return message
        }
    }

    var isTransientNetworkFailure: Bool {
        if case .transientNetwork = self {
            return true
        }
        return false
    }
}
