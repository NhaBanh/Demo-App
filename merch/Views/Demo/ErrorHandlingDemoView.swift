import SwiftUI

// MARK: - Error Handling Demo View

struct ErrorHandlingDemoView: View {
    @StateObject private var viewModel = ErrorDemoViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("Error Handling Demo")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top)

                    Text("Tap buttons to see different error types and presentations")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Divider()
                        .padding(.vertical)

                    // Network Errors
                    errorSection(title: "Network Errors") {
                        errorButton("No Connection", icon: "wifi.slash") {
                            viewModel.showError(NetworkError.noConnection, style: .alert)
                        }

                        errorButton("Timeout", icon: "clock.badge.exclamationmark") {
                            viewModel.showError(NetworkError.timeout, style: .banner)
                        }

                        errorButton("Server Error", icon: "server.rack") {
                            viewModel.showError(NetworkError.serverError(statusCode: 500), style: .fullScreen)
                        }

                        errorButton("Invalid Response", icon: "exclamationmark.triangle") {
                            viewModel.showError(NetworkError.invalidResponse, style: .alert)
                        }
                    }

                    // Service Errors
                    errorSection(title: "Service Errors") {
                        errorButton("Product Not Found", icon: "magnifyingglass") {
                            viewModel.showError(ServiceError.productNotFound(id: "ABC123"), style: .alert)
                        }

                        errorButton("Out of Stock", icon: "cart.badge.minus") {
                            viewModel.showError(ServiceError.outOfStock(productName: "Antigravity Hoodie"), style: .banner)
                        }

                        errorButton("Cart Empty", icon: "cart") {
                            viewModel.showError(ServiceError.cartEmpty, style: .alert)
                        }

                        errorButton("Service Unavailable", icon: "exclamationmark.octagon") {
                            viewModel.showError(ServiceError.serviceUnavailable, style: .fullScreen)
                        }
                    }

                    // Validation Errors
                    errorSection(title: "Validation Errors") {
                        errorButton("Invalid Email", icon: "envelope.badge.fill") {
                            viewModel.showError(ValidationError.invalidEmail, style: .alert)
                        }

                        errorButton("Password Too Short", icon: "lock.shield") {
                            viewModel.showError(ValidationError.passwordTooShort(minLength: 8), style: .alert)
                        }

                        errorButton("Empty Field", icon: "textformat") {
                            viewModel.showError(ValidationError.emptyField(fieldName: "Username"), style: .banner)
                        }

                        errorButton("Invalid Credit Card", icon: "creditcard") {
                            viewModel.showError(ValidationError.invalidCreditCard, style: .alert)
                        }
                    }

                    // Persistence Errors
                    errorSection(title: "Persistence Errors") {
                        errorButton("Save Failed", icon: "square.and.arrow.down") {
                            viewModel.showError(PersistenceError.saveFailed(reason: "Disk full"), style: .alert)
                        }

                        errorButton("Corrupted Data", icon: "exclamationmark.triangle.fill") {
                            viewModel.showError(PersistenceError.corruptedData, style: .fullScreen)
                        }

                        errorButton("Storage Full", icon: "externaldrive.fill.badge.exclamationmark") {
                            viewModel.showError(PersistenceError.storageQuotaExceeded, style: .banner)
                        }
                    }

                    // Presentation Styles
                    Divider()
                        .padding(.vertical)

                    Text("Presentation Styles")
                        .font(.headline)
                        .padding(.top)

                    VStack(spacing: 12) {
                        presentationButton("Alert Style", icon: "bell.fill", color: .blue) {
                            viewModel.showError(NetworkError.noConnection, style: .alert)
                        }

                        presentationButton("Banner Style", icon: "rectangle.topthird.inset.filled", color: .orange) {
                            viewModel.showError(ServiceError.productNotFound(id: "123"), style: .banner)
                        }

                        presentationButton("Full Screen Style", icon: "rectangle.fill", color: .red) {
                            viewModel.showError(NetworkError.serverError(statusCode: 503), style: .fullScreen)
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .errorAlert($viewModel.alertError)
        .errorBanner(error: viewModel.bannerError, onDismiss: {
            viewModel.dismissBanner()
        })
        .fullScreenCover(isPresented: $viewModel.showFullScreenError) {
            if let error = viewModel.fullScreenError {
                NavigationView {
                    ErrorStateView(error: error) {
                        viewModel.dismissFullScreen()
                    }
                    .navigationBarItems(trailing: Button("Close") {
                        viewModel.dismissFullScreen()
                    })
                }
            }
        }
    }

    // MARK: - Helper Views

    private func errorSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 8) {
                content()
            }
            .padding(.horizontal)
        }
    }

    private func errorButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func presentationButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(color)
            .cornerRadius(12)
        }
    }
}

// MARK: - Demo View Model

@MainActor
class ErrorDemoViewModel: ObservableObject {
    @Published var alertError: AppError?
    @Published var bannerError: AppError?
    @Published var fullScreenError: AppError?
    @Published var showFullScreenError = false

    func showError(_ error: AppError, style: ErrorPresentationStyle) {
        switch style {
        case .alert:
            alertError = error

        case .banner:
            bannerError = error
            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                self?.dismissBanner()
            }

        case .fullScreen:
            fullScreenError = error
            showFullScreenError = true

        case .inline:
            // Not implemented in this demo
            break
        }

        // Log for debugging
        print("🔴 Demo Error: [\(error.errorCode)] \(error.title)")
        print("   Message: \(error.message)")
        if let suggestion = error.recoverySuggestion {
            print("   Suggestion: \(suggestion)")
        }
    }

    func dismissBanner() {
        withAnimation {
            bannerError = nil
        }
    }

    func dismissFullScreen() {
        showFullScreenError = false
        fullScreenError = nil
    }
}

// MARK: - Preview

struct ErrorHandlingDemoView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorHandlingDemoView()
    }
}
