import XCTest
@testable import ToDo

final class SetWishlistQuantityUseCaseTests: XCTestCase {
    func testExecutePersistsQuantityWhenIncreaseIsAvailableAndWithinStock() throws {
        let repository = WishlistRepositoryFake()
        repository.setQuantityResult = .success(4)
        let item = BuyItem.fixture(availability: .available, availableQuantity: 5)
        let useCase = SetWishlistQuantityUseCase(repository: repository)

        let updatedQuantity = try useCase.execute(
            item: item,
            currentQuantity: 2,
            newQuantity: 4
        )

        XCTAssertEqual(updatedQuantity, 4)
        XCTAssertEqual(repository.setQuantityCalls.count, 1)
        XCTAssertEqual(repository.setQuantityCalls.first?.quantity, 4)
    }

    func testExecuteAllowsDecreaseWhenItemIsUnavailable() throws {
        let repository = WishlistRepositoryFake()
        repository.setQuantityResult = .success(1)
        let item = BuyItem.fixture(availability: .outOfStock, availableQuantity: 0)
        let useCase = SetWishlistQuantityUseCase(repository: repository)

        let updatedQuantity = try useCase.execute(
            item: item,
            currentQuantity: 2,
            newQuantity: 1
        )

        XCTAssertEqual(updatedQuantity, 1)
        XCTAssertEqual(repository.setQuantityCalls.first?.quantity, 1)
    }

    func testExecuteThrowsWhenQuantityExceedsAvailableStock() {
        let repository = WishlistRepositoryFake()
        let item = BuyItem.fixture(availability: .available, availableQuantity: 2)
        let useCase = SetWishlistQuantityUseCase(repository: repository)

        XCTAssertThrowsError(
            try useCase.execute(item: item, currentQuantity: 1, newQuantity: 3)
        ) { error in
            XCTAssertEqual(
                (error as? AppError)?.errorDescription,
                "Wishlist quantity cannot exceed available stock (2)."
            )
        }
        XCTAssertTrue(repository.setQuantityCalls.isEmpty)
    }

    func testExecuteThrowsWhenUnavailableItemIsIncreased() {
        let repository = WishlistRepositoryFake()
        let item = BuyItem.fixture(availability: .outOfStock, availableQuantity: 0)
        let useCase = SetWishlistQuantityUseCase(repository: repository)

        XCTAssertThrowsError(
            try useCase.execute(item: item, currentQuantity: 0, newQuantity: 1)
        ) { error in
            XCTAssertEqual(
                (error as? AppError)?.errorDescription,
                "Wishlist quantity can only be increased while the item is available."
            )
        }
        XCTAssertTrue(repository.setQuantityCalls.isEmpty)
    }
}
