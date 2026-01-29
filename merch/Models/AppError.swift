import Foundation

// MARK: - Base App Error Protocol

/// Base protocol for all app errors
protocol AppError: LocalizedError {
    var title: String { get }
    var message: String { get }
    var recoverySuggestion: String? { get }
    var errorCode: String { get }
}

// MARK: - Network Errors

enum NetworkError: AppError {
    case noConnection
    case timeout
    case serverError(statusCode: Int)
    case invalidResponse
    case invalidURL
    case decodingFailed(Error)
    case unknown(Error)

    var title: String {
        switch self {
        case .noConnection:
            return "No Internet Connection"
        case .timeout:
            return "Request Timeout"
        case .serverError:
            return "Server Error"
        case .invalidResponse:
            return "Invalid Response"
        case .invalidURL:
            return "Invalid URL"
        case .decodingFailed:
            return "Data Error"
        case .unknown:
            return "Network Error"
        }
    }

    var message: String {
        switch self {
        case .noConnection:
            return "Please check your internet connection and try again."
        case .timeout:
            return "The request took too long to complete. Please try again."
        case .serverError(let statusCode):
            return "The server returned an error (Code: \(statusCode)). Please try again later."
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .invalidURL:
            return "The requested URL is invalid."
        case .decodingFailed(let error):
            return "Failed to process the data: \(error.localizedDescription)"
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Check your WiFi or cellular connection."
        case .timeout:
            return "Try again with a better connection."
        case .serverError:
            return "Wait a few minutes and try again."
        case .invalidResponse, .decodingFailed:
            return "Contact support if this persists."
        case .invalidURL:
            return "This appears to be an app issue. Please update the app."
        case .unknown:
            return "Try restarting the app."
        }
    }

    var errorCode: String {
        switch self {
        case .noConnection:
            return "NET_001"
        case .timeout:
            return "NET_002"
        case .serverError(let code):
            return "NET_003_\(code)"
        case .invalidResponse:
            return "NET_004"
        case .invalidURL:
            return "NET_005"
        case .decodingFailed:
            return "NET_006"
        case .unknown:
            return "NET_999"
        }
    }

    var errorDescription: String? {
        return message
    }
}

// MARK: - Service Errors

enum ServiceError: AppError {
    case productNotFound(id: String)
    case cartEmpty
    case cartItemNotFound(id: String)
    case invalidQuantity
    case outOfStock(productName: String)
    case priceMismatch
    case serviceUnavailable

    var title: String {
        switch self {
        case .productNotFound:
            return "Product Not Found"
        case .cartEmpty:
            return "Cart is Empty"
        case .cartItemNotFound:
            return "Item Not Found"
        case .invalidQuantity:
            return "Invalid Quantity"
        case .outOfStock:
            return "Out of Stock"
        case .priceMismatch:
            return "Price Changed"
        case .serviceUnavailable:
            return "Service Unavailable"
        }
    }

    var message: String {
        switch self {
        case .productNotFound(let id):
            return "The product with ID '\(id)' could not be found."
        case .cartEmpty:
            return "Your cart is empty. Add some items to continue."
        case .cartItemNotFound(let id):
            return "The cart item with ID '\(id)' could not be found."
        case .invalidQuantity:
            return "Please enter a valid quantity (1-99)."
        case .outOfStock(let name):
            return "'\(name)' is currently out of stock."
        case .priceMismatch:
            return "The price has changed since you added this item to your cart."
        case .serviceUnavailable:
            return "This service is temporarily unavailable."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .productNotFound:
            return "Try browsing other products."
        case .cartEmpty:
            return "Browse our products and add items to your cart."
        case .cartItemNotFound:
            return "Refresh your cart."
        case .invalidQuantity:
            return "Enter a number between 1 and 99."
        case .outOfStock:
            return "Check back later or browse similar items."
        case .priceMismatch:
            return "Review the new price before proceeding."
        case .serviceUnavailable:
            return "Try again in a few minutes."
        }
    }

    var errorCode: String {
        switch self {
        case .productNotFound:
            return "SVC_001"
        case .cartEmpty:
            return "SVC_002"
        case .cartItemNotFound:
            return "SVC_003"
        case .invalidQuantity:
            return "SVC_004"
        case .outOfStock:
            return "SVC_005"
        case .priceMismatch:
            return "SVC_006"
        case .serviceUnavailable:
            return "SVC_999"
        }
    }

    var errorDescription: String? {
        return message
    }
}

// MARK: - Validation Errors

enum ValidationError: AppError {
    case emptyField(fieldName: String)
    case invalidEmail
    case invalidPhoneNumber
    case passwordTooShort(minLength: Int)
    case passwordsDoNotMatch
    case invalidCreditCard
    case invalidCVV
    case invalidExpiryDate

    var title: String {
        switch self {
        case .emptyField:
            return "Required Field"
        case .invalidEmail:
            return "Invalid Email"
        case .invalidPhoneNumber:
            return "Invalid Phone Number"
        case .passwordTooShort:
            return "Password Too Short"
        case .passwordsDoNotMatch:
            return "Passwords Don't Match"
        case .invalidCreditCard:
            return "Invalid Card Number"
        case .invalidCVV:
            return "Invalid CVV"
        case .invalidExpiryDate:
            return "Invalid Expiry Date"
        }
    }

    var message: String {
        switch self {
        case .emptyField(let fieldName):
            return "\(fieldName) is required."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .invalidPhoneNumber:
            return "Please enter a valid phone number."
        case .passwordTooShort(let minLength):
            return "Password must be at least \(minLength) characters long."
        case .passwordsDoNotMatch:
            return "The passwords you entered do not match."
        case .invalidCreditCard:
            return "Please enter a valid credit card number."
        case .invalidCVV:
            return "Please enter a valid CVV (3-4 digits)."
        case .invalidExpiryDate:
            return "Please enter a valid expiry date (MM/YY)."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .emptyField:
            return "Please fill in this field."
        case .invalidEmail:
            return "Use format: example@email.com"
        case .invalidPhoneNumber:
            return "Use format: (123) 456-7890"
        case .passwordTooShort(let minLength):
            return "Use at least \(minLength) characters."
        case .passwordsDoNotMatch:
            return "Make sure both passwords are identical."
        case .invalidCreditCard:
            return "Check the card number and try again."
        case .invalidCVV:
            return "Find the CVV on the back of your card."
        case .invalidExpiryDate:
            return "Check the expiry date on your card."
        }
    }

    var errorCode: String {
        switch self {
        case .emptyField:
            return "VAL_001"
        case .invalidEmail:
            return "VAL_002"
        case .invalidPhoneNumber:
            return "VAL_003"
        case .passwordTooShort:
            return "VAL_004"
        case .passwordsDoNotMatch:
            return "VAL_005"
        case .invalidCreditCard:
            return "VAL_006"
        case .invalidCVV:
            return "VAL_007"
        case .invalidExpiryDate:
            return "VAL_008"
        }
    }

    var errorDescription: String? {
        return message
    }
}

// MARK: - Persistence Errors

enum PersistenceError: AppError {
    case saveFailed(reason: String)
    case loadFailed(reason: String)
    case deleteFailed(reason: String)
    case corruptedData
    case storageQuotaExceeded

    var title: String {
        switch self {
        case .saveFailed:
            return "Save Failed"
        case .loadFailed:
            return "Load Failed"
        case .deleteFailed:
            return "Delete Failed"
        case .corruptedData:
            return "Corrupted Data"
        case .storageQuotaExceeded:
            return "Storage Full"
        }
    }

    var message: String {
        switch self {
        case .saveFailed(let reason):
            return "Failed to save data: \(reason)"
        case .loadFailed(let reason):
            return "Failed to load data: \(reason)"
        case .deleteFailed(let reason):
            return "Failed to delete data: \(reason)"
        case .corruptedData:
            return "The stored data is corrupted and cannot be read."
        case .storageQuotaExceeded:
            return "Device storage is full. Free up space to continue."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .saveFailed, .loadFailed, .deleteFailed:
            return "Try restarting the app."
        case .corruptedData:
            return "The app will reset to default settings."
        case .storageQuotaExceeded:
            return "Delete some files or apps to free up space."
        }
    }

    var errorCode: String {
        switch self {
        case .saveFailed:
            return "PER_001"
        case .loadFailed:
            return "PER_002"
        case .deleteFailed:
            return "PER_003"
        case .corruptedData:
            return "PER_004"
        case .storageQuotaExceeded:
            return "PER_005"
        }
    }

    var errorDescription: String? {
        return message
    }
}

// MARK: - Error Wrapper for Generic Errors

struct GenericAppError: AppError {
    let title: String
    let message: String
    let recoverySuggestion: String?
    let errorCode: String

    var errorDescription: String? {
        return message
    }

    init(title: String, message: String, recoverySuggestion: String? = nil, errorCode: String = "GEN_001") {
        self.title = title
        self.message = message
        self.recoverySuggestion = recoverySuggestion
        self.errorCode = errorCode
    }
}

// MARK: - Error Converter

/// Converts standard Swift errors to AppError
struct ErrorConverter {
    static func convert(_ error: Error) -> AppError {
        // Check if already an AppError
        if let appError = error as? AppError {
            return appError
        }

        // Check for NSError types
        if let nsError = error as NSError? {
            switch nsError.domain {
            case NSURLErrorDomain:
                return convertURLError(nsError)
            case NSCocoaErrorDomain:
                return convertCocoaError(nsError)
            default:
                break
            }
        }

        // Default generic error
        return GenericAppError(
            title: "Error",
            message: error.localizedDescription,
            recoverySuggestion: "Please try again.",
            errorCode: "GEN_999"
        )
    }

    private static func convertURLError(_ error: NSError) -> AppError {
        switch error.code {
        case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
            return NetworkError.noConnection
        case NSURLErrorTimedOut:
            return NetworkError.timeout
        case NSURLErrorBadURL:
            return NetworkError.invalidURL
        case NSURLErrorCannotDecodeContentData, NSURLErrorCannotDecodeRawData:
            return NetworkError.decodingFailed(error)
        default:
            return NetworkError.unknown(error)
        }
    }

    private static func convertCocoaError(_ error: NSError) -> AppError {
        switch error.code {
        case NSFileReadCorruptFileError:
            return PersistenceError.corruptedData
        case NSFileWriteOutOfSpaceError:
            return PersistenceError.storageQuotaExceeded
        default:
            return GenericAppError(
                title: "System Error",
                message: error.localizedDescription,
                errorCode: "SYS_\(error.code)"
            )
        }
    }
}
