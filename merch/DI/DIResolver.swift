import Foundation

// MARK: - Dependency Resolver Helper

/// A helper utility to make constructor injection cleaner and less verbose
enum DIResolver {

    /// Resolves a dependency from the DI container synchronously
    /// This is a convenience wrapper around the DependencyContainer
    ///
    /// Usage:
    /// ```swift
    /// init(productService: ProductService? = nil) {
    ///     self.productService = productService ?? DIResolver.resolve()
    /// }
    /// ```
    static func resolve<T>(_ type: T.Type = T.self) -> T {
        do {
            return try DependencyContainer.shared.resolve(type)
        } catch {
            fatalError("Failed to resolve \(type): \(error.localizedDescription)")
        }
    }

    /// Resolves a dependency with a default fallback
    /// Returns the default value if resolution fails
    ///
    /// Usage:
    /// ```swift
    /// init(productService: ProductService? = nil) {
    ///     self.productService = productService ?? DIResolver.resolve(default: MockProductService())
    /// }
    /// ```
    static func resolve<T>(default defaultValue: T) -> T {
        return DependencyContainer.shared.resolve(T.self, default: defaultValue)
    }

    /// Resolves a dependency asynchronously (for use in async contexts)
    ///
    /// Usage:
    /// ```swift
    /// let service = try await DIResolver.resolveAsync(ProductService.self)
    /// ```
    static func resolveAsync<T>(_ type: T.Type = T.self) async throws -> T {
        return try DependencyContainer.shared.resolve(type)
    }

    /// Checks if a dependency is registered
    ///
    /// Usage:
    /// ```swift
    /// if DIResolver.isRegistered(ProductService.self) {
    ///     // Use the service
    /// }
    /// ```
    static func isRegistered<T>(_ type: T.Type) -> Bool {
        return DependencyContainer.shared.isRegistered(type)
    }
}

// MARK: - Convenience Operator (Optional)

/// Convenience operator for resolving dependencies
/// Usage: let service = productService ?? ~>ProductService.self
infix operator ~>: NilCoalescingPrecedence

func ~> <T>(lhs: T?, rhs: T.Type) -> T {
    return lhs ?? DIResolver.resolve(rhs)
}
