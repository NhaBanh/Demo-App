import SwiftUI

// MARK: - Error Alert View

struct ErrorAlertView: ViewModifier {
    @Binding var error: AppError?

    func body(content: Content) -> some View {
        content
            .alert(error?.title ?? "Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }

                if error?.recoverySuggestion != nil {
                    Button("Help") {
                        // Could open help documentation or support
                        print("Help requested for error: \(error?.errorCode ?? "")")
                    }
                }
            } message: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(error?.message ?? "")

                    if let suggestion = error?.recoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
    }
}

// MARK: - Error Banner View

struct ErrorBannerView: View {
    let error: AppError
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 4) {
                Text(error.title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(error.message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }

    private var iconName: String {
        switch error {
        case is NetworkError:
            return "wifi.exclamationmark"
        case is ServiceError:
            return "exclamationmark.triangle.fill"
        case is ValidationError:
            return "exclamationmark.circle.fill"
        case is PersistenceError:
            return "externaldrive.fill.badge.exclamationmark"
        default:
            return "exclamationmark.circle.fill"
        }
    }

    private var backgroundColor: Color {
        switch error {
        case is NetworkError:
            return Color.orange
        case is ServiceError:
            return Color.red
        case is ValidationError:
            return Color.yellow.opacity(0.8)
        case is PersistenceError:
            return Color.purple
        default:
            return Color.gray
        }
    }
}

// MARK: - Error State View

struct ErrorStateView: View {
    let error: AppError
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Text(error.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(error.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 4)
                }
            }

            if let retry = retryAction {
                Button(action: retry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(10)
                }
                .padding(.top, 8)
            }

            Text("Error Code: \(error.errorCode)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding()
    }

    private var iconName: String {
        switch error {
        case is NetworkError:
            return "wifi.slash"
        case is ServiceError:
            return "exclamationmark.triangle"
        case is ValidationError:
            return "checkmark.shield"
        case is PersistenceError:
            return "externaldrive.badge.exclamationmark"
        default:
            return "exclamationmark.circle"
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Shows an error alert when an AppError is present
    func errorAlert(_ error: Binding<AppError?>) -> some View {
        modifier(ErrorAlertView(error: error))
    }

    /// Shows an error banner at the top of the view
    func errorBanner(error: AppError?, onDismiss: @escaping () -> Void) -> some View {
        ZStack(alignment: .top) {
            self

            if let error = error {
                ErrorBannerView(error: error, onDismiss: onDismiss)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(), value: error != nil)
                    .padding(.top, 8)
            }
        }
    }
}

// MARK: - Error Presentation Style

enum ErrorPresentationStyle {
    case alert
    case banner
    case inline
    case fullScreen
}

// MARK: - Error Handler View Model

@MainActor
class ErrorHandlerViewModel: ObservableObject {
    @Published var currentError: AppError?
    @Published var presentationStyle: ErrorPresentationStyle = .alert
    @Published var showError = false

    /// Present an error with a specific style
    func present(_ error: Error, style: ErrorPresentationStyle = .alert) {
        let appError = ErrorConverter.convert(error)
        self.currentError = appError
        self.presentationStyle = style
        self.showError = true

        // Auto-dismiss banner after 5 seconds
        if style == .banner {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.dismiss()
            }
        }
    }

    /// Dismiss the current error
    func dismiss() {
        withAnimation {
            showError = false
            currentError = nil
        }
    }

    /// Handle error with logging
    func handle(_ error: Error, style: ErrorPresentationStyle = .alert, logToAnalytics: Bool = true) {
        let appError = ErrorConverter.convert(error)

        // Log to console (in production, send to analytics)
        print("❌ Error [\(appError.errorCode)]: \(appError.title)")
        print("   Message: \(appError.message)")
        if let suggestion = appError.recoverySuggestion {
            print("   Suggestion: \(suggestion)")
        }

        // Present to user
        present(appError, style: style)

        // Send to analytics if needed
        if logToAnalytics {
            logErrorToAnalytics(appError)
        }
    }

    private func logErrorToAnalytics(_ error: AppError) {
        // In production, integrate with Firebase Analytics, Crashlytics, etc.
        // For now, just print
        print("📊 Analytics: Error logged - \(error.errorCode)")
    }
}

// MARK: - Example Usage in a View

struct ErrorHandlingExampleView: View {
    @StateObject private var errorHandler = ErrorHandlerViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Error Handling Examples")
                .font(.title)

            Button("Show Alert Error") {
                errorHandler.present(
                    NetworkError.noConnection,
                    style: .alert
                )
            }

            Button("Show Banner Error") {
                errorHandler.present(
                    ServiceError.productNotFound(id: "123"),
                    style: .banner
                )
            }

            Button("Show Full Screen Error") {
                errorHandler.present(
                    ValidationError.invalidEmail,
                    style: .fullScreen
                )
            }
        }
        .errorAlert($errorHandler.currentError)
        .errorBanner(
            error: errorHandler.presentationStyle == .banner ? errorHandler.currentError : nil,
            onDismiss: { errorHandler.dismiss() }
        )
    }
}
