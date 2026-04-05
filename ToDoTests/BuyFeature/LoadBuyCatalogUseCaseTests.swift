import XCTest
@testable import ToDo

final class LoadBuyCatalogUseCaseTests: XCTestCase {
    func testExecuteMergesWishlistQuantityWithoutAppendingWishlistOnlyItems() async throws {
        let remoteItem = BuyItem.fixture(id: UUID(), title: "Remote", availableQuantity: 8)
        let wishlistOnlyItem = BuyItem.fixture(id: UUID(), title: "Wishlist Only", availability: .available)
        let buyRepository = BuyRepositoryFake()
        buyRepository.fetchItemsResult = .success(
            BuyItemsPage(items: [remoteItem], page: 2, pageSize: 20, totalCount: 21, hasMore: true)
        )

        let wishlistRepository = WishlistRepositoryFake()
        wishlistRepository.records = [
            .fixture(item: remoteItem, quantity: 3),
            .fixture(item: wishlistOnlyItem, quantity: 2)
        ]

        let useCase = LoadBuyCatalogUseCase(
            buyRepository: buyRepository,
            wishlistRepository: wishlistRepository
        )

        let page = try await useCase.execute(
            sort: .priceLowToHigh,
            availability: .available,
            category: .office,
            page: 2,
            pageSize: 20
        )

        XCTAssertEqual(buyRepository.receivedQueries, [
            BuyCatalogQuery(
                sort: .priceLowToHigh,
                availability: .available,
                category: .office,
                page: 2,
                pageSize: 20
            )
        ])
        XCTAssertEqual(page.items.count, 1)
        XCTAssertEqual(page.items[0], BuyCatalogListItem(item: remoteItem, wishlistQuantity: 3))
        XCTAssertEqual(page.page, 2)
        XCTAssertTrue(page.hasMore)
    }
}
