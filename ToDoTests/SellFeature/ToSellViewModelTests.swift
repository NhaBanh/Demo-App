import XCTest
@testable import ToDo

@MainActor
final class ToSellViewModelTests: XCTestCase {
    func testRefreshLoadsItemsAndMetadata() async {
        let item = SellItem.fixture()
        let repository = SellRepositoryFake()
        repository.fetchItemsResult = .success(
            SellItemsPage(items: [item], page: 1, pageSize: 20, totalCount: 1, hasMore: false)
        )
        let viewModel = makeViewModel(repository: repository)

        await viewModel.refresh()

        XCTAssertEqual(viewModel.items, [item])
        XCTAssertEqual(viewModel.totalCount, 1)
        XCTAssertFalse(viewModel.hasMore)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testDeleteStoresLastDeletedItems() async {
        let deleted = SellItem.fixture()
        let repository = SellRepositoryFake()
        repository.deleteResult = .success([deleted])
        repository.fetchItemsResult = .success(
            SellItemsPage(items: [], page: 1, pageSize: 20, totalCount: 0, hasMore: false)
        )
        let viewModel = makeViewModel(repository: repository)

        await viewModel.delete(ids: [deleted.id])

        XCTAssertEqual(viewModel.lastDeletedItems, [deleted])
        XCTAssertEqual(repository.receivedDeleteIDs, [[deleted.id]])
    }

    func testSellReducesQuantityThroughRepositoryUpdate() async {
        let item = SellItem.fixture(quantity: 4)
        let repository = SellRepositoryFake()
        repository.fetchItemResult = .success(item)
        repository.updateResult = .success(
            SellItem.fixture(
                id: item.id,
                title: item.title,
                askingPrice: item.askingPrice,
                quantity: 2,
                detail: item.detail,
                status: item.status,
                createdAt: item.createdAt
            )
        )
        repository.fetchItemsResult = .success(
            SellItemsPage(items: [], page: 1, pageSize: 20, totalCount: 0, hasMore: false)
        )
        let viewModel = makeViewModel(repository: repository)

        await viewModel.sell(item: item, amount: 2)

        XCTAssertEqual(repository.receivedFetchIDs, [item.id])
        XCTAssertEqual(repository.receivedUpdatedItems.first?.quantity, 2)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testUndoDeleteRestoresItemsAndClearsUndoState() async {
        let deleted = SellItem.fixture()
        let repository = SellRepositoryFake()
        repository.deleteResult = .success([deleted])
        repository.fetchItemsResult = .success(
            SellItemsPage(items: [], page: 1, pageSize: 20, totalCount: 0, hasMore: false)
        )
        let viewModel = makeViewModel(repository: repository)

        await viewModel.delete(ids: [deleted.id])
        await viewModel.undoDelete()

        XCTAssertEqual(repository.receivedRestoreItems, [[deleted]])
        XCTAssertTrue(viewModel.lastDeletedItems.isEmpty)
    }

    private func makeViewModel(repository: SellRepositoryFake) -> ToSellViewModel {
        ToSellViewModel(
            inventoryReader: repository,
            inventoryWriter: repository,
            createItem: CreateSellItemUseCase(repository: repository),
            updateItem: UpdateSellItemUseCase(repository: repository),
            sellAmount: SellAmountUseCase(repository: repository)
        )
    }
}
