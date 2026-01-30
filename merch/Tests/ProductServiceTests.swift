import XCTest
@testable import merch

class ProductServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset DI container before each test
        DependencyContainer.shared.reset()
    }

    func testMockProductServiceFetchesProducts() async throws {
        // Given
        let mockService = MockProductService()
        DependencyContainer.shared.register(ProductService.self) { mockService }

        // When
        let products = try await mockService.fetchProducts()

        // Then
        XCTAssertFalse(products.isEmpty)
        XCTAssertEqual(products.count, 4) // Assuming 4 mock products
    }

    func testMockProductServiceFetchesProductById() async throws {
        // Given
        let mockService = MockProductService()
        DependencyContainer.shared.register(ProductService.self) { mockService }

        // When
        let product = try await mockService.fetchProduct(id: "1")

        // Then
        XCTAssertEqual(product.id, "1")
        XCTAssertEqual(product.name, "Classic T-Shirt")
    }

    func testMockProductServiceThrowsErrorWhenProductNotFound() async {
        // Given
        let mockService = MockProductService()
        DependencyContainer.shared.register(ProductService.self) { mockService }

        // When/Then
        do {
            _ = try await mockService.fetchProduct(id: "999")
            XCTFail("Should throw error")
        } catch let error as ServiceError {
            // Expected error
            if case .productNotFound(let id) = error {
                XCTAssertEqual(id, "999")
            } else {
                XCTFail("Wrong error type")
            }
        } catch {
            XCTFail("Wrong error type")
        }
    }
}
