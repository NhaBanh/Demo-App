# Error Handling System Documentation

## Overview

This app implements a comprehensive, type-safe error handling system with custom error types, user-friendly error messages, and reusable UI components.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Error Flow                              |
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Service Layer          ViewModel Layer        View Layer   │
│  ┌──────────┐          ┌──────────┐          ┌──────────┐   │
│  │ Throws   │   ──→    │ Converts │   ──→    │ Displays │   │
│  │ Error    │          │ to       │          │ Error    │   │
│  │          │          │ AppError │          │ UI       │   │
│  └──────────┘          └──────────┘          └──────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Error Types

### 1. **AppError Protocol**

Base protocol that all custom errors conform to:

```swift
protocol AppError: LocalizedError {
    var title: String { get }           // Short error title
    var message: String { get }         // Detailed message
    var recoverySuggestion: String? { get } // How to fix it
    var errorCode: String { get }       // Unique error code
}
```

### 2. **NetworkError**

Handles all network-related errors:

| Error | Code | Description |
|-------|------|-------------|
| `noConnection` | NET_001 | No internet connection |
| `timeout` | NET_002 | Request timed out |
| `serverError(statusCode)` | NET_003_XXX | Server returned error |
| `invalidResponse` | NET_004 | Invalid server response |
| `invalidURL` | NET_005 | Malformed URL |
| `decodingFailed(Error)` | NET_006 | JSON decoding failed |
| `unknown(Error)` | NET_999 | Unknown network error |

**Example Usage:**
```swift
func fetchData() async throws -> Data {
    guard let url = URL(string: apiURL) else {
        throw NetworkError.invalidURL
    }

    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw NetworkError.invalidResponse
    }

    if httpResponse.statusCode >= 500 {
        throw NetworkError.serverError(statusCode: httpResponse.statusCode)
    }

    return data
}
```

### 3. **ServiceError**

Handles business logic and service-specific errors:

| Error | Code | Description |
|-------|------|-------------|
| `productNotFound(id)` | SVC_001 | Product doesn't exist |
| `cartEmpty` | SVC_002 | Cart has no items |
| `cartItemNotFound(id)` | SVC_003 | Cart item not found |
| `invalidQuantity` | SVC_004 | Invalid quantity value |
| `outOfStock(name)` | SVC_005 | Product out of stock |
| `priceMismatch` | SVC_006 | Price changed |
| `serviceUnavailable` | SVC_999 | Service unavailable |

**Example Usage:**
```swift
func fetchProduct(id: String) async throws -> Product {
    guard let product = products.first(where: { $0.id == id }) else {
        throw ServiceError.productNotFound(id: id)
    }
    return product
}
```

### 4. **ValidationError**

Handles input validation errors:

| Error | Code | Description |
|-------|------|-------------|
| `emptyField(name)` | VAL_001 | Required field is empty |
| `invalidEmail` | VAL_002 | Email format invalid |
| `invalidPhoneNumber` | VAL_003 | Phone number invalid |
| `passwordTooShort(min)` | VAL_004 | Password too short |
| `passwordsDoNotMatch` | VAL_005 | Passwords don't match |
| `invalidCreditCard` | VAL_006 | Invalid card number |
| `invalidCVV` | VAL_007 | Invalid CVV |
| `invalidExpiryDate` | VAL_008 | Invalid expiry date |

**Example Usage:**
```swift
func validateEmail(_ email: String) throws {
    guard !email.isEmpty else {
        throw ValidationError.emptyField(fieldName: "Email")
    }

    let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)

    guard emailPredicate.evaluate(with: email) else {
        throw ValidationError.invalidEmail
    }
}
```

### 5. **PersistenceError**

Handles data storage errors:

| Error | Code | Description |
|-------|------|-------------|
| `saveFailed(reason)` | PER_001 | Failed to save data |
| `loadFailed(reason)` | PER_002 | Failed to load data |
| `deleteFailed(reason)` | PER_003 | Failed to delete data |
| `corruptedData` | PER_004 | Data is corrupted |
| `storageQuotaExceeded` | PER_005 | Storage is full |

## Error Converter

Automatically converts standard Swift/Foundation errors to AppError:

```swift
let appError = ErrorConverter.convert(standardError)
```

**Supported Conversions:**
- URLSession errors → NetworkError
- NSError (file operations) → PersistenceError
- Generic errors → GenericAppError

## UI Components

### 1. **ErrorStateView**

Full-screen error display with retry button:

```swift
ErrorStateView(error: error) {
    // Retry action
    await viewModel.retryLoadProducts()
}
```

**Features:**
- Large icon based on error type
- Error title and message
- Recovery suggestion
- Retry button (optional)
- Error code display

### 2. **ErrorBannerView**

Dismissible banner at top of screen:

```swift
.errorBanner(error: viewModel.error) {
    viewModel.clearError()
}
```

**Features:**
- Color-coded by error type
- Auto-dismisses after 5 seconds
- Swipe to dismiss
- Icon based on error type

### 3. **ErrorAlertView**

Standard iOS alert dialog:

```swift
.errorAlert($viewModel.error)
```

**Features:**
- Native iOS alert
- OK button to dismiss
- Optional Help button
- Shows recovery suggestion

### 4. **ErrorHandlerViewModel**

Centralized error handling:

```swift
@StateObject private var errorHandler = ErrorHandlerViewModel()

// Present error
errorHandler.present(error, style: .banner)

// Handle with logging
errorHandler.handle(error, style: .alert, logToAnalytics: true)
```

## Usage Patterns

### Pattern 1: ViewModel Error Handling

```swift
@MainActor
class MyViewModel: ObservableObject {
    @Published var error: AppError?
    @Published var isLoading = false

    func loadData() async {
        isLoading = true
        error = nil

        do {
            let data = try await service.fetchData()
            // Process data
        } catch {
            self.error = ErrorConverter.convert(error)
            print("❌ Error: \(self.error?.errorCode ?? "UNKNOWN")")
        }

        isLoading = false
    }

    func retry() async {
        await loadData()
    }

    func clearError() {
        error = nil
    }
}
```

### Pattern 2: View with Error Display

```swift
struct MyView: View {
    @StateObject private var viewModel = MyViewModel()

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                ErrorStateView(error: error) {
                    Task { await viewModel.retry() }
                }
            } else {
                // Content
            }
        }
        .task {
            await viewModel.loadData()
        }
    }
}
```

### Pattern 3: Service Layer

```swift
class MyService {
    func fetchData() async throws -> Data {
        // Validate input
        guard isValid else {
            throw ValidationError.emptyField(fieldName: "Query")
        }

        // Check network
        guard hasConnection else {
            throw NetworkError.noConnection
        }

        // Make request
        do {
            let data = try await makeRequest()
            return data
        } catch {
            // Convert to appropriate error type
            throw ErrorConverter.convert(error)
        }
    }
}
```

## Best Practices

### ✅ DO

1. **Always use custom error types** in your services
2. **Convert errors at the ViewModel layer** using ErrorConverter
3. **Provide recovery suggestions** for all errors
4. **Log errors with error codes** for debugging
5. **Use appropriate UI components** based on context
6. **Test error scenarios** in your unit tests
7. **Provide retry mechanisms** where appropriate

### ❌ DON'T

1. **Don't use generic Error types** in your public APIs
2. **Don't show raw error messages** to users
3. **Don't crash the app** on recoverable errors
4. **Don't ignore errors** silently
5. **Don't use fatalError()** for expected error cases
6. **Don't show technical details** to end users

## Error Presentation Decision Tree

```
Is the error critical?
├─ Yes → Use ErrorStateView (full screen)
└─ No
   ├─ Is it user-actionable?
   │  ├─ Yes → Use ErrorAlertView (alert)
   │  └─ No → Use ErrorBannerView (banner)
   └─ Is it transient?
      ├─ Yes → Use ErrorBannerView (auto-dismiss)
      └─ No → Use ErrorAlertView (requires acknowledgment)
```

## Testing Errors

### Mock Service with Error Simulation

```swift
class MockProductService: ProductService {
    var shouldSimulateError = false
    var simulatedError: Error?

    func fetchProducts() async throws -> [Product] {
        if shouldSimulateError {
            throw simulatedError ?? NetworkError.noConnection
        }
        return mockProducts
    }
}
```

### Unit Test Example

```swift
func testErrorHandling() async throws {
    // Arrange
    let mockService = MockProductService()
    mockService.shouldSimulateError = true
    mockService.simulatedError = NetworkError.timeout

    let viewModel = HomeViewModel(productService: mockService)

    // Act
    await viewModel.loadProducts()

    // Assert
    XCTAssertNotNil(viewModel.error)
    XCTAssertEqual(viewModel.error?.errorCode, "NET_002")
}
```

## Analytics Integration

Track errors for monitoring:

```swift
func logErrorToAnalytics(_ error: AppError) {
    // Firebase Analytics
    Analytics.logEvent("error_occurred", parameters: [
        "error_code": error.errorCode,
        "error_title": error.title,
        "error_message": error.message
    ])

    // Crashlytics (for non-fatal errors)
    Crashlytics.crashlytics().record(error: error)
}
```

## Summary

This error handling system provides:

- ✅ **Type Safety**: Compile-time error checking
- ✅ **User-Friendly**: Clear, actionable error messages
- ✅ **Debuggable**: Unique error codes for tracking
- ✅ **Consistent**: Unified error handling across the app
- ✅ **Testable**: Easy to mock and test error scenarios
- ✅ **Maintainable**: Centralized error definitions
- ✅ **Extensible**: Easy to add new error types

## Future Enhancements

- [ ] Localization support for error messages
- [ ] Error retry with exponential backoff
- [ ] Offline error queue
- [ ] Error reporting to backend
- [ ] A/B testing for error messages
- [ ] Error recovery workflows
