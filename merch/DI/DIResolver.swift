import Foundation

// MARK: - Dependency Resolver Helper

/// A helper utility to make constructor injection cleaner and less verbose
enum DIResolver {

    /// Resolves a dependency from the DI container synchronously
    /// This is a convenience wrapper around the async DependencyContainer
    ///
    /// Usage:
    /// ```swift
    /// init(productService: ProductService? = nil) {
    ///     self.productService = productService ?? DIResolver.resolve()
    /// }
    /// ```
    static func resolve<T>(_ type: T.Type = T.self) -> T {
        let semaphore = DispatchSemaphore(value: 0)
        var resolved: T?
        var resolutionError: Error?

        Task {
            do {
                resolved = try await DependencyContainer.shared.resolve(type)
            } catch {
                resolutionError = error
            }
            semaphore.signal()
        }

        semaphore.wait()

        if let error = resolutionError {
            fatalError("Failed to resolve \(type): \(error.localizedDescription)")
        }

        guard let service = resolved else {
            fatalError("Failed to resolve \(type): Unknown error")
        }

        return service
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
        let semaphore = DispatchSemaphore(value: 0)
        var resolved: T?

        Task {
            resolved = await DependencyContainer.shared.resolve(T.self, default: defaultValue)
            semaphore.signal()
        }

        semaphore.wait()
        return resolved ?? defaultValue
    }

    /// Resolves a dependency asynchronously (for use in async contexts)
    ///
    /// Usage:
    /// ```swift
    /// let service = try await DIResolver.resolveAsync(ProductService.self)
    /// ```
    static func resolveAsync<T>(_ type: T.Type = T.self) async throws -> T {
        return try await DependencyContainer.shared.resolve(type)
    }

    /// Checks if a dependency is registered
    ///
    /// Usage:
    /// ```swift
    /// if await DIResolver.isRegistered(ProductService.self) {
    ///     // Use the service
    /// }
    /// ```
    static func isRegistered<T>(_ type: T.Type) async -> Bool {
        return await DependencyContainer.shared.isRegistered(type)
    }
}

// MARK: - Convenience Operator (Optional)

/// Convenience operator for resolving dependencies
/// Usage: let service = productService ?? ~>ProductService.self
infix operator ~>: NilCoalescingPrecedence

func ~> <T>(lhs: T?, rhs: T.Type) -> T {
    return lhs ?? DIResolver.resolve(rhs)
}


