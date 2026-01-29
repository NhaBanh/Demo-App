import Foundation

// MARK: - Dependency Injection Errors

enum DIError: Error, LocalizedError {
    case serviceNotRegistered(String)
    case factoryNotRegistered(String)
    case typeMismatch(expected: String, actual: String)

    var errorDescription: String? {
        switch self {
        case .serviceNotRegistered(let type):
            return "No service registered for type: \(type)"
        case .factoryNotRegistered(let type):
            return "No factory registered for type: \(type)"
        case .typeMismatch(let expected, let actual):
            return "Type mismatch - Expected: \(expected), Actual: \(actual)"
        }
    }
}

// MARK: - Service Scope

enum ServiceScope {
    case singleton  // Single instance shared across the app
    case transient  // New instance created each time
}

// MARK: - Service Registration

private struct ServiceRegistration {
    let scope: ServiceScope
    let factory: () -> Any
    var cachedInstance: Any?

    init(scope: ServiceScope, factory: @escaping () -> Any) {
        self.scope = scope
        self.factory = factory
        self.cachedInstance = nil
    }
}

// MARK: - Dependency Container

/// A type-safe Dependency Injection container using ObjectIdentifier for better type safety.
actor DependencyContainer {
    static let shared = DependencyContainer()

    private var registrations: [ObjectIdentifier: ServiceRegistration] = [:]

    private init() {
        // Register default services
        Task {
            await registerDefaults()
        }
    }

    /// Registers default services for the app
    private func registerDefaults() {
        register(ProductService.self, scope: .singleton) {
            MockProductService()
        }
    }

    /// Registers a service with a factory closure
    /// - Parameters:
    ///   - type: The protocol or class type to register
    ///   - scope: The lifecycle scope of the service (singleton or transient)
    ///   - factory: A closure that creates an instance of the service
    func register<T>(_ type: T.Type, scope: ServiceScope = .singleton, factory: @escaping () -> T) {
        let key = ObjectIdentifier(type)
        registrations[key] = ServiceRegistration(scope: scope, factory: factory)
    }

    /// Registers a concrete instance as a singleton
    /// - Parameters:
    ///   - type: The protocol or class type to register
    ///   - instance: The concrete instance to register
    func register<T>(_ type: T.Type, instance: T) {
        let key = ObjectIdentifier(type)
        var registration = ServiceRegistration(scope: .singleton) { instance }
        registration.cachedInstance = instance
        registrations[key] = registration
    }

    /// Resolves and returns a service for a given type
    /// - Parameter type: The type to resolve
    /// - Returns: An instance of the requested type
    /// - Throws: DIError if the service is not registered
    func resolve<T>(_ type: T.Type) throws -> T {
        let key = ObjectIdentifier(type)

        guard var registration = registrations[key] else {
            throw DIError.serviceNotRegistered(String(describing: type))
        }

        switch registration.scope {
        case .singleton:
            if let cached = registration.cachedInstance as? T {
                return cached
            }
            let instance = registration.factory()
            guard let typedInstance = instance as? T else {
                throw DIError.typeMismatch(
                    expected: String(describing: type),
                    actual: String(describing: Swift.type(of: instance))
                )
            }
            registration.cachedInstance = typedInstance
            registrations[key] = registration
            return typedInstance

        case .transient:
            let instance = registration.factory()
            guard let typedInstance = instance as? T else {
                throw DIError.typeMismatch(
                    expected: String(describing: type),
                    actual: String(describing: Swift.type(of: instance))
                )
            }
            return typedInstance
        }
    }

    /// Resolves a service with a default fallback
    /// - Parameters:
    ///   - type: The type to resolve
    ///   - default: A default instance to return if resolution fails
    /// - Returns: The resolved instance or the default
    func resolve<T>(_ type: T.Type, default: T) -> T {
        do {
            return try resolve(type)
        } catch {
            return `default`
        }
    }

    /// Checks if a service is registered
    /// - Parameter type: The type to check
    /// - Returns: True if the service is registered
    func isRegistered<T>(_ type: T.Type) -> Bool {
        let key = ObjectIdentifier(type)
        return registrations[key] != nil
    }

    /// Unregisters a service
    /// - Parameter type: The type to unregister
    func unregister<T>(_ type: T.Type) {
        let key = ObjectIdentifier(type)
        registrations.removeValue(forKey: key)
    }

    /// Clears all registrations (useful for testing)
    func reset() {
        registrations.removeAll()
    }
}

// MARK: - Property Wrapper for Dependency Injection

/// Property wrapper for automatic dependency injection
/// Usage: @Injected var productService: ProductService
@propertyWrapper
struct Injected<T> {
    private var service: T?

    public var wrappedValue: T {
        mutating get {
            if service == nil {
                // Use a synchronous wrapper for the async actor call
                service = resolveService()
            }
            return service!
        }
        mutating set {
            service = newValue
        }
    }

    private func resolveService() -> T {
        // This is a workaround since property wrappers can't be async
        // In production, consider using a different pattern or Swift 6 features
        let semaphore = DispatchSemaphore(value: 0)
        var resolved: T?

        Task {
            do {
                resolved = try await DependencyContainer.shared.resolve(T.self)
            } catch {
                fatalError("Failed to resolve dependency: \(error.localizedDescription)")
            }
            semaphore.signal()
        }

        semaphore.wait()
        return resolved!
    }

    public init() {
        self.service = nil
    }
}

// MARK: - Convenience Extensions

extension DependencyContainer {
    /// Convenience method for registering multiple services at once
    func registerServices(@ServiceBuilder _ builder: () -> [ServiceRegistrationItem]) async {
        let items = builder()
        for item in items {
            await item.register(in: self)
        }
    }
}

// MARK: - Service Builder (for cleaner registration)

@resultBuilder
struct ServiceBuilder {
    static func buildBlock(_ components: ServiceRegistrationItem...) -> [ServiceRegistrationItem] {
        components
    }
}

protocol ServiceRegistrationItem {
    func register(in container: DependencyContainer) async
}

struct ServiceRegistrationWrapper<T>: ServiceRegistrationItem {
    let type: T.Type
    let scope: ServiceScope
    let factory: () -> T

    func register(in container: DependencyContainer) async {
        await container.register(type, scope: scope, factory: factory)
    }
}
