import Combine
import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var error: AppError?

    private let productService: ProductService

    init(productService: ProductService? = nil) {
        // Clean constructor injection using DIResolver
        self.productService = productService ?? DIResolver.resolve()
    }

    func loadProducts() async {
        isLoading = true
        error = nil

        do {
            products = try await productService.fetchProducts()
        } catch {
            // Convert any error to AppError
            self.error = ErrorConverter.convert(error)

            // Log error for debugging
            print("❌ Failed to load products: \(self.error?.errorCode ?? "UNKNOWN")")
            print("   Message: \(self.error?.message ?? "Unknown error")")
        }

        isLoading = false
    }

    func retryLoadProducts() async {
        await loadProducts()
    }

    func clearError() {
        error = nil
    }
}
