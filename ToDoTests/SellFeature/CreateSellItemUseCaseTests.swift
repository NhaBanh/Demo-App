import XCTest
@testable import ToDo

final class CreateSellItemUseCaseTests: XCTestCase {
    func testExecuteTrimsInputsBeforeCreatingItem() async throws {
        let repository = SellRepositoryFake()
        repository.createResult = .success(.fixture(title: "Desk Lamp", detail: "Warm light"))
        let useCase = CreateSellItemUseCase(repository: repository)

        _ = try await useCase.execute(
            title: "  Desk Lamp  ",
            askingPrice: 49,
            quantity: 3,
            detail: "  Warm light  "
        )

        XCTAssertEqual(repository.receivedCreatedItems.count, 1)
        XCTAssertEqual(repository.receivedCreatedItems.first?.title, "Desk Lamp")
        XCTAssertEqual(repository.receivedCreatedItems.first?.detail, "Warm light")
        XCTAssertEqual(repository.receivedCreatedItems.first?.status, .active)
    }

    func testExecuteRejectsZeroQuantityOnCreate() async {
        let repository = SellRepositoryFake()
        let useCase = CreateSellItemUseCase(repository: repository)

        do {
            _ = try await useCase.execute(title: "Desk Lamp", askingPrice: 49, quantity: 0, detail: "")
            XCTFail("Expected validation error")
        } catch {
            XCTAssertEqual((error as? AppError)?.errorDescription, "Quantity must be greater than zero.")
        }

        XCTAssertTrue(repository.receivedCreatedItems.isEmpty)
    }
}
