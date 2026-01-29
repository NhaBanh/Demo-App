import Foundation

protocol ProductService {
    func fetchProducts() async throws -> [Product]
    func fetchProduct(id: String) async throws -> Product
}

class MockProductService: ProductService {
    private let mockProducts: [Product] = [
        Product(id: "1", name: "Classic T-Shirt", description: "A comfortable classic t-shirt made from 100% cotton.", price: 25.0, imageUrl: "https://images.unsplash.com/photo-1521572267360-ee0c2909d518?w=500&auto=format&fit=crop", category: "Apparel"),
        Product(id: "2", name: "Antigravity Hoodie", description: "Stay warm with this premium hoodie featuring our signature logo.", price: 55.0, imageUrl: "https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=500&auto=format&fit=crop", category: "Apparel"),
        Product(id: "3", name: "Space Cap", description: "Adjustable cap for all your space missions.", price: 20.0, imageUrl: "https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=500&auto=format&fit=crop", category: "Accessories"),
        Product(id: "4", name: "Developer Mug", description: "The perfect mug for your daily dose of coffee and code.", price: 15.0, imageUrl: "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=500&auto=format&fit=crop", category: "Lifestyle")
    ]

    // Simulate network conditions for testing
    var shouldSimulateError = false
    var simulatedError: Error?
    var simulateTimeout = false

    func fetchProducts() async throws -> [Product] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Simulate timeout
        if simulateTimeout {
            throw NetworkError.timeout
        }

        // Simulate error if configured
        if shouldSimulateError {
            if let error = simulatedError {
                throw error
            }
            throw NetworkError.noConnection
        }

        return mockProducts
    }

    func fetchProduct(id: String) async throws -> Product {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)

        // Simulate timeout
        if simulateTimeout {
            throw NetworkError.timeout
        }

        // Simulate error if configured
        if shouldSimulateError {
            if let error = simulatedError {
                throw error
            }
            throw NetworkError.noConnection
        }

        // Find product or throw custom error
        guard let product = mockProducts.first(where: { $0.id == id }) else {
            throw ServiceError.productNotFound(id: id)
        }

        return product
    }
}

// MARK: - Real API Product Service (Template)

class APIProductService: ProductService {
    private let baseURL = "https://api.example.com"

    func fetchProducts() async throws -> [Product] {
        guard let url = URL(string: "\(baseURL)/products") else {
            throw NetworkError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                break // Success
            case 404:
                throw ServiceError.serviceUnavailable
            case 500...599:
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            default:
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }

            // Decode response
            do {
                let products = try JSONDecoder().decode([Product].self, from: data)
                return products
            } catch {
                throw NetworkError.decodingFailed(error)
            }

        } catch let error as NetworkError {
            throw error
        } catch let error as ServiceError {
            throw error
        } catch {
            // Convert URLSession errors to NetworkError
            throw ErrorConverter.convert(error)
        }
    }

    func fetchProduct(id: String) async throws -> Product {
        guard let url = URL(string: "\(baseURL)/products/\(id)") else {
            throw NetworkError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                break
            case 404:
                throw ServiceError.productNotFound(id: id)
            case 500...599:
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            default:
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }

            do {
                let product = try JSONDecoder().decode(Product.self, from: data)
                return product
            } catch {
                throw NetworkError.decodingFailed(error)
            }

        } catch let error as NetworkError {
            throw error
        } catch let error as ServiceError {
            throw error
        } catch {
            throw ErrorConverter.convert(error)
        }
    }
}

