import XCTest
@testable import ToDo

final class SQLiteSellStoreTests: XCTestCase {
    func testInsertAndFetchSoldOutItemsAllowsQuantityZero() async throws {
        let filename = TestStoreHelpers.makeSQLiteFilename(prefix: "sqlite-sold-out")
        defer { TestStoreHelpers.removeSQLiteFile(named: filename) }
        let store = SQLiteSellStore(filename: filename)
        let soldOut = SellItem.fixture(quantity: 0, updatedAt: .now)

        try await store.insertSellItem(soldOut)

        let page = try await store.fetchSellItems(
            query: SellItemsQuery(status: .soldOut, page: 1, pageSize: 20)
        )

        XCTAssertEqual(page.items.count, 1)
        let fetched = try XCTUnwrap(page.items.first)
        XCTAssertEqual(fetched.id, soldOut.id)
        XCTAssertEqual(fetched.title, soldOut.title)
        XCTAssertEqual(fetched.askingPrice, soldOut.askingPrice)
        XCTAssertEqual(fetched.quantity, soldOut.quantity)
        XCTAssertEqual(fetched.detail, soldOut.detail)
        XCTAssertEqual(fetched.status, soldOut.status)
        XCTAssertEqual(fetched.createdAt.timeIntervalSince1970, soldOut.createdAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(fetched.updatedAt.timeIntervalSince1970, soldOut.updatedAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(page.totalCount, 1)
        XCTAssertFalse(page.hasMore)
    }

    func testFetchSellItemsPaginatesByUpdatedAtDescending() async throws {
        let filename = TestStoreHelpers.makeSQLiteFilename(prefix: "sqlite-paging")
        defer { TestStoreHelpers.removeSQLiteFile(named: filename) }
        let store = SQLiteSellStore(filename: filename)
        let older = SellItem.fixture(title: "Older", updatedAt: Date(timeIntervalSince1970: 100))
        let newer = SellItem.fixture(title: "Newer", updatedAt: Date(timeIntervalSince1970: 200))

        try await store.insertSellItem(older)
        try await store.insertSellItem(newer)

        let firstPage = try await store.fetchSellItems(
            query: SellItemsQuery(status: .all, page: 1, pageSize: 1)
        )
        let secondPage = try await store.fetchSellItems(
            query: SellItemsQuery(status: .all, page: 2, pageSize: 1)
        )

        XCTAssertEqual(firstPage.items.map(\.title), ["Newer"])
        XCTAssertTrue(firstPage.hasMore)
        XCTAssertEqual(secondPage.items.map(\.title), ["Older"])
        XCTAssertFalse(secondPage.hasMore)
    }

    func testLegacySellOneOperationDecodesAsUpdate() async throws {
        let legacy = QueuedSellOperation.OperationType(databaseValue: "sellOne")
        let olderLegacy = QueuedSellOperation.OperationType(databaseValue: "markSold")

        XCTAssertEqual(legacy, .update)
        XCTAssertEqual(olderLegacy, .update)
    }
}
