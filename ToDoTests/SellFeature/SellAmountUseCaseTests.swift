import XCTest
@testable import ToDo

final class SellAmountUseCaseTests: XCTestCase {
    func testExecuteReducesQuantityAndPersistsUpdate() async throws {
        let id = UUID()
        let existing = SellItem.fixture(id: id, quantity: 5, status: .active)
        let repository = SellRepositoryFake()
        repository.fetchItemResult = .success(existing)
        repository.updateResult = .success(
            SellItem.fixture(
                id: id,
                title: existing.title,
                askingPrice: existing.askingPrice,
                quantity: 3,
                detail: existing.detail,
                status: existing.status,
                createdAt: existing.createdAt
            )
        )
        let useCase = SellAmountUseCase(repository: repository)

        let result = try await useCase.execute(itemID: id, amount: 2)

        XCTAssertEqual(repository.receivedFetchIDs, [id])
        XCTAssertEqual(repository.receivedUpdatedItems.count, 1)
        XCTAssertEqual(repository.receivedUpdatedItems.first?.quantity, 3)
        XCTAssertEqual(result.quantity, 3)
    }

    func testExecuteThrowsWhenAmountExceedsAvailableQuantity() async {
        let id = UUID()
        let existing = SellItem.fixture(id: id, quantity: 1, status: .active)
        let repository = SellRepositoryFake()
        repository.fetchItemResult = .success(existing)
        let useCase = SellAmountUseCase(repository: repository)

        do {
            _ = try await useCase.execute(itemID: id, amount: 2)
            XCTFail("Expected validation error")
        } catch {
            XCTAssertEqual(
                (error as? AppError)?.errorDescription,
                "Sold amount cannot exceed available quantity."
            )
        }

        XCTAssertTrue(repository.receivedUpdatedItems.isEmpty)
    }

    func testExecuteThrowsWhenItemIsArchived() async {
        let id = UUID()
        let existing = SellItem.fixture(id: id, quantity: 3, status: .archived)
        let repository = SellRepositoryFake()
        repository.fetchItemResult = .success(existing)
        let useCase = SellAmountUseCase(repository: repository)

        do {
            _ = try await useCase.execute(itemID: id, amount: 1)
            XCTFail("Expected validation error")
        } catch {
            XCTAssertEqual(
                (error as? AppError)?.errorDescription,
                "Archived items cannot be sold."
            )
        }

        XCTAssertTrue(repository.receivedUpdatedItems.isEmpty)
    }
}
