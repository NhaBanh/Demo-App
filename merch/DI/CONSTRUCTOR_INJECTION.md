# Constructor Injection with DependencyContainer

## 🎯 Quick Start

### The Simplest Way (Recommended)

```swift
import Foundation

@MainActor
class MyViewModel: ObservableObject {
    private let productService: ProductService

    init(productService: ProductService? = nil) {
        self.productService = productService ?? DIResolver.resolve()
    }
}
```

---

## 📚 Complete Examples

### Example 1: Single Dependency

```swift
@MainActor
class ProductListViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var error: AppError?

    private let productService: ProductService

    // Constructor injection with optional parameter
    init(productService: ProductService? = nil) {
        self.productService = productService ?? DIResolver.resolve()
    }

    func loadProducts() async {
        do {
            products = try await productService.fetchProducts()
        } catch {
            error = ErrorConverter.convert(error)
        }
    }
}

// Production usage
let viewModel = ProductListViewModel()  // Uses DI container

// Testing usage
let mockService = MockProductService()
let viewModel = ProductListViewModel(productService: mockService)  // Uses mock
```

### Example 2: Multiple Dependencies

```swift
@MainActor
class CheckoutViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var error: AppError?

    private let productService: ProductService
    private let cartService: CartService
    private let paymentService: PaymentService

    init(
        productService: ProductService? = nil,
        cartService: CartService? = nil,
        paymentService: PaymentService? = nil
    ) {
        // Clean and simple with DIResolver!
        self.productService = productService ?? DIResolver.resolve()
        self.cartService = cartService ?? DIResolver.resolve()
        self.paymentService = paymentService ?? DIResolver.resolve()
    }

    func checkout() async {
        isProcessing = true

        do {
            let items = try await cartService.getItems()
            let total = try await cartService.calculateTotal()
            try await paymentService.processPayment(amount: total)
            try await cartService.clear()
        } catch {
            error = ErrorConverter.convert(error)
        }

        isProcessing = false
    }
}

// Production usage
let viewModel = CheckoutViewModel()

// Testing usage
let viewModel = CheckoutViewModel(
    productService: mockProductService,
    cartService: mockCartService,
    paymentService: mockPaymentService
)
```

### Example 3: Using in SwiftUI Views

```swift
struct ProductListView: View {
    @StateObject private var viewModel = ProductListViewModel()

    var body: some View {
        List(viewModel.products) { product in
            ProductRow(product: product)
        }
        .task {
            await viewModel.loadProducts()
        }
    }
}

// For previews with mock data
struct ProductListView_Previews: PreviewProvider {
    static var previews: some View {
        let mockService = MockProductService()
        let viewModel = ProductListViewModel(productService: mockService)
        ProductListViewWithViewModel(viewModel: viewModel)
    }
}
```

### Example 4: Service Layer

```swift
class ProductCatalogService {
    private let productService: ProductService
    private let cacheService: CacheService

    init(
        productService: ProductService? = nil,
        cacheService: CacheService? = nil
    ) {
        self.productService = productService ?? DIResolver.resolve()
        self.cacheService = cacheService ?? DIResolver.resolve()
    }

    func getProducts(forceRefresh: Bool = false) async throws -> [Product] {
        if !forceRefresh, let cached = cacheService.get("products") as? [Product] {
            return cached
        }

        let products = try await productService.fetchProducts()
        cacheService.set("products", value: products)
        return products
    }
}
```

---

## 🧪 Testing Examples

### Basic Test

```swift
func testLoadProducts() async {
    // Arrange
    let mockService = MockProductService()
    let viewModel = ProductListViewModel(productService: mockService)

    // Act
    await viewModel.loadProducts()

    // Assert
    XCTAssertEqual(viewModel.products.count, 4)
    XCTAssertNil(viewModel.error)
}
```

### Test with Error

```swift
func testLoadProductsWithError() async {
    // Arrange
    let mockService = MockProductService()
    mockService.shouldSimulateError = true
    mockService.simulatedError = NetworkError.noConnection

    let viewModel = ProductListViewModel(productService: mockService)

    // Act
    await viewModel.loadProducts()

    // Assert
    XCTAssertTrue(viewModel.products.isEmpty)
    XCTAssertNotNil(viewModel.error)
    XCTAssertEqual(viewModel.error?.errorCode, "NET_001")
}
```

### Test Multiple Dependencies

```swift
func testCheckout() async {
    // Arrange
    let mockProductService = MockProductService()
    let mockCartService = MockCartService()
    let mockPaymentService = MockPaymentService()

    // Add items to cart
    let product = mockProductService.mockProducts[0]
    try! await mockCartService.addItem(CartItem(product: product, quantity: 2))

    let viewModel = CheckoutViewModel(
        productService: mockProductService,
        cartService: mockCartService,
        paymentService: mockPaymentService
    )

    // Act
    await viewModel.checkout()

    // Assert
    let items = try! await mockCartService.getItems()
    XCTAssertTrue(items.isEmpty, "Cart should be empty after checkout")
    XCTAssertNil(viewModel.error)
}
```

---

## 🎨 Advanced Patterns

### Pattern 1: Using Custom Operator (Ultra Clean)

```swift
@MainActor
class MyViewModel: ObservableObject {
    private let productService: ProductService
    private let cartService: CartService

    init(
        productService: ProductService? = nil,
        cartService: CartService? = nil
    ) {
        // Ultra clean with ~> operator!
        self.productService = productService ~> ProductService.self
        self.cartService = cartService ~> CartService.self
    }
}
```

### Pattern 2: With Default Fallback

```swift
@MainActor
class MyViewModel: ObservableObject {
    private let productService: ProductService

    init(productService: ProductService? = nil) {
        // Provide a safe default if resolution fails
        self.productService = productService ?? DIResolver.resolve(
            default: MockProductService()
        )
    }
}
```

### Pattern 3: Async Resolution (in async context)

```swift
class MyService {
    private var productService: ProductService?

    func initialize() async throws {
        // Use async resolution when already in async context
        self.productService = try await DIResolver.resolveAsync()
    }
}
```

---

## 🚫 Common Mistakes to Avoid

### ❌ Don't resolve in methods

```swift
// BAD!
func loadData() async {
    let service = DIResolver.resolve()  // ❌ Don't do this
    // ...
}

// GOOD!
init(service: MyService? = nil) {
    self.service = service ?? DIResolver.resolve()  // ✅ Do this
}
```

### ❌ Don't make dependencies mutable

```swift
// BAD!
private var productService: ProductService  // ❌ var

// GOOD!
private let productService: ProductService  // ✅ let
```

### ❌ Don't create dependencies directly

```swift
// BAD!
init() {
    self.productService = MockProductService()  // ❌ Tight coupling
}

// GOOD!
init(productService: ProductService? = nil) {
    self.productService = productService ?? DIResolver.resolve()  // ✅ Flexible
}
```

---

## 🚫 Best Practices

### ✅ DO:

 1. Use DIResolver.resolve() for clean constructor injection
    init(service: Service? = nil) {
        self.service = service ?? DIResolver.resolve()
    }

 2. Use the ~> operator for even cleaner code
    self.service = service ~> Service.self

 3. Use DIResolver.resolve(default:) for safe fallbacks
    self.service = service ?? DIResolver.resolve(default: MockService())

 4. Use DIResolver.resolveAsync() in async contexts
    self.service = try await DIResolver.resolveAsync()

### ❌ DON'T:

 1. Don't use DIResolver in property wrappers
    ✗ @Injected is already available for that

 2. Don't resolve in methods (resolve in constructor)
    ✗ func doSomething() {
          let service = DIResolver.resolve()  // BAD!
      }
    ✓ init() {
          self.service = DIResolver.resolve()  // GOOD!
      }

 3. Don't ignore resolution errors in production
    ✗ Use proper error handling
