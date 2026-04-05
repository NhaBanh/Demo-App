import Foundation

enum TransientErrorClassifier {
    static func isRetryableNetworkFailure(_ error: Error) -> Bool {
        if let appError = error as? AppError {
            return appError.isTransientNetworkFailure
        }

        return error is URLError
    }
}
