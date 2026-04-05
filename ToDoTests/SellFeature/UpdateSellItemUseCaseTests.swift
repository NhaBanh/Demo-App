import XCTest
@testable import ToDo

final class UpdateSellItemUseCaseTests: XCTestCase {
    func testExecuteUpdatesNormalizedItemAndAllowsZeroQuantity() async throws {
        let id = UUID()
        let existing = SellItem.fixture(id: id, quantity: 2)
        let repository = SellRepositoryFake()
        repository.fetchItemResult = .success(existing)
        repository.updateResult = .success(.fixture(id: id, title: "Desk Lamp", quantity: 0, detail: "Warm light"))
        let useCase = UpdateSellItemUseCase(repository: repository)

        let updated = SellItem.fixture(
            id: id,
            title: "  Desk Lamp  ",
            quantity: 0,
            detail: "  Warm light  "
        )

        _ = try await useCase.execute(updated)

        XCTAssertEqual(repository.receivedFetchIDs, [id])
        XCTAssertEqual(repository.receivedUpdatedItems.count, 1)
        XCTAssertEqual(repository.receivedUpdatedItems.first?.title, "Desk Lamp")
        XCTAssertEqual(repository.receivedUpdatedItems.first?.detail, "Warm light")
        XCTAssertEqual(repository.receivedUpdatedItems.first?.quantity, 0)
    }

    func testExecuteThrowsWhenExistingItemIsMissing() async {
        let repository = SellRepositoryFake()
        repository.fetchItemResult = .success(nil)
        let useCase = UpdateSellItemUseCase(repository: repository)

        do {
            _ = try await useCase.execute(.fixture())
            XCTFail("Expected persistence error")
        } catch {
            XCTAssertEqual((error as? AppError)?.errorDescription, "Sell item could not be found.")
        }

        XCTAssertTrue(repository.receivedUpdatedItems.isEmpty)
    }
}
