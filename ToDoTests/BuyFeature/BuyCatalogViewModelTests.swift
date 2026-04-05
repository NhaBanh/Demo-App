import XCTest
@testable import ToDo

@MainActor
final class BuyCatalogViewModelTests: XCTestCase {
    func testRefreshLoadsItemsAndMetadata() async {
        let first = BuyCatalogListItem.fixture(item: .fixture(title: "Printer Ink"), wishlistQuantity: 1)
        let second = BuyCatalogListItem.fixture(item: .fixture(title: "Desk Lamp"), wishlistQuantity: 0)
        let buyRepository = BuyRepositoryFake()
        buyRepository.fetchItemsResult = .success(
            BuyItemsPage(items: [first.item, second.item], page: 1, pageSize: 20, totalCount: 2, hasMore: false)
        )
        let wishlistRepository = WishlistRepositoryFake()
        wishlistRepository.records = [
            .fixture(item: first.item, quantity: 1)
        ]

        let viewModel = BuyCatalogViewModel(
            loadItems: LoadBuyCatalogUseCase(buyRepository: buyRepository, wishlistRepository: wishlistRepository),
            setWishlistQuantity: SetWishlistQuantityUseCase(repository: wishlistRepository)
        )

        await viewModel.refresh()

        XCTAssertEqual(viewModel.items, [first, BuyCatalogListItem(item: second.item, wishlistQuantity: 0)])
        XCTAssertEqual(viewModel.totalCount, 2)
        XCTAssertFalse(viewModel.hasMore)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testRefreshPassesSelectedRemoteFilters() async {
        let item = BuyCatalogListItem.fixture(item: .fixture(title: "Printer Ink", category: .hardware))
        let buyRepository = BuyRepositoryFake()
        buyRepository.fetchItemsResult = .success(
            BuyItemsPage(items: [item.item], page: 1, pageSize: 20, totalCount: 1, hasMore: false)
        )
        let wishlistRepository = WishlistRepositoryFake()
        let viewModel = BuyCatalogViewModel(
            loadItems: LoadBuyCatalogUseCase(buyRepository: buyRepository, wishlistRepository: wishlistRepository),
            setWishlistQuantity: SetWishlistQuantityUseCase(repository: wishlistRepository)
        )
        viewModel.availabilityFilter = .available
        viewModel.categoryFilter = .hardware

        await viewModel.refresh()

        XCTAssertEqual(
            buyRepository.receivedQueries,
            [BuyCatalogQuery(
                sort: .title,
                availability: .available,
                category: .hardware,
                page: 1,
                pageSize: 20
            )]
        )
    }

    func testLoadNextPageIfNeededAppendsNextPage() async {
        let firstPageItem = BuyCatalogListItem.fixture(item: .fixture(title: "A"))
        let secondPageItem = BuyCatalogListItem.fixture(item: .fixture(title: "B"))
        let buyRepository = BuyRepositoryFake()
        buyRepository.fetchItemsHandler = { query in
            if query.page == 1 {
                return BuyItemsPage(items: [firstPageItem.item], page: 1, pageSize: 20, totalCount: 2, hasMore: true)
            }
            return BuyItemsPage(items: [secondPageItem.item], page: 2, pageSize: 20, totalCount: 2, hasMore: false)
        }
        let wishlistRepository = WishlistRepositoryFake()
        let viewModel = BuyCatalogViewModel(
            loadItems: LoadBuyCatalogUseCase(buyRepository: buyRepository, wishlistRepository: wishlistRepository),
            setWishlistQuantity: SetWishlistQuantityUseCase(repository: wishlistRepository)
        )

        await viewModel.refresh()
        await viewModel.loadNextPageIfNeeded(currentItem: firstPageItem)

        XCTAssertEqual(viewModel.items.map(\.item.title), ["A", "B"])
        XCTAssertEqual(buyRepository.receivedQueries.map(\.page), [1, 2])
        XCTAssertFalse(viewModel.hasMore)
    }

    func testSaveToWishlistAddsOneToUnsavedItemAndLeavesOthersUntouched() async {
        let target = BuyCatalogListItem.fixture(item: .fixture(title: "Target"), wishlistQuantity: 0)
        let other = BuyCatalogListItem.fixture(item: .fixture(title: "Other"), wishlistQuantity: 2)
        let buyRepository = BuyRepositoryFake()
        buyRepository.fetchItemsResult = .success(
            BuyItemsPage(items: [target.item, other.item], page: 1, pageSize: 20, totalCount: 2, hasMore: false)
        )
        let wishlistRepository = WishlistRepositoryFake()
        wishlistRepository.records = [
            .fixture(item: other.item, quantity: 2)
        ]
        wishlistRepository.setQuantityResult = .success(1)

        let viewModel = BuyCatalogViewModel(
            loadItems: LoadBuyCatalogUseCase(buyRepository: buyRepository, wishlistRepository: wishlistRepository),
            setWishlistQuantity: SetWishlistQuantityUseCase(repository: wishlistRepository)
        )

        await viewModel.refresh()
        await viewModel.saveToWishlist(target)

        XCTAssertEqual(viewModel.items.first?.wishlistQuantity, 1)
        XCTAssertEqual(viewModel.items.last?.wishlistQuantity, 2)
        XCTAssertEqual(wishlistRepository.setQuantityCalls.first?.quantity, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSaveToWishlistDoesNothingWhenItemIsAlreadySaved() async {
        let saved = BuyCatalogListItem.fixture(item: .fixture(title: "Saved"), wishlistQuantity: 2)
        let buyRepository = BuyRepositoryFake()
        buyRepository.fetchItemsResult = .success(
            BuyItemsPage(items: [saved.item], page: 1, pageSize: 20, totalCount: 1, hasMore: false)
        )
        let wishlistRepository = WishlistRepositoryFake()
        wishlistRepository.records = [.fixture(item: saved.item, quantity: 2)]
        let viewModel = BuyCatalogViewModel(
            loadItems: LoadBuyCatalogUseCase(buyRepository: buyRepository, wishlistRepository: wishlistRepository),
            setWishlistQuantity: SetWishlistQuantityUseCase(repository: wishlistRepository)
        )

        await viewModel.refresh()
        await viewModel.saveToWishlist(saved)

        XCTAssertEqual(viewModel.items.first?.wishlistQuantity, 2)
        XCTAssertTrue(wishlistRepository.setQuantityCalls.isEmpty)
    }

    func testLatestSortChangeWinsWhenRequestsFinishOutOfOrder() async {
        let titleSorted = BuyItem.fixture(title: "Title Result", price: 50)
        let priceSorted = BuyItem.fixture(title: "Price Result", price: 10)
        let buyRepository = BuyRepositoryFake()
        buyRepository.fetchItemsHandler = { query in
            switch query.sort {
            case .title:
                try await Task.sleep(nanoseconds: 300_000_000)
                return BuyItemsPage(items: [titleSorted], page: 1, pageSize: 20, totalCount: 1, hasMore: false)
            case .priceLowToHigh:
                try await Task.sleep(nanoseconds: 50_000_000)
                return BuyItemsPage(items: [priceSorted], page: 1, pageSize: 20, totalCount: 1, hasMore: false)
            case .priceHighToLow:
                return BuyItemsPage(items: [titleSorted], page: 1, pageSize: 20, totalCount: 1, hasMore: false)
            }
        }
        let wishlistRepository = WishlistRepositoryFake()
        let viewModel = BuyCatalogViewModel(
            loadItems: LoadBuyCatalogUseCase(buyRepository: buyRepository, wishlistRepository: wishlistRepository),
            setWishlistQuantity: SetWishlistQuantityUseCase(repository: wishlistRepository)
        )

        viewModel.sort = .title
        let firstTask = Task { await viewModel.sortDidChange() }
        await Task.yield()

        viewModel.sort = .priceLowToHigh
        await viewModel.sortDidChange()
        await firstTask.value

        XCTAssertEqual(viewModel.items, [
            BuyCatalogListItem(item: priceSorted, wishlistQuantity: 0)
        ])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadOnAppearDoesNotReloadWhenDataIsFresh() async {
        let availableItem = BuyCatalogListItem.fixture(
            item: .fixture(title: "Desk Lamp", availability: .available),
            wishlistQuantity: 1
        )
        let buyRepository = BuyRepositoryFake()
        buyRepository.fetchItemsResult = .success(
            BuyItemsPage(items: [availableItem.item], page: 1, pageSize: 20, totalCount: 1, hasMore: false)
        )
        let wishlistRepository = WishlistRepositoryFake()
        wishlistRepository.records = [.fixture(item: availableItem.item, quantity: 1)]
        let viewModel = BuyCatalogViewModel(
            loadItems: LoadBuyCatalogUseCase(buyRepository: buyRepository, wishlistRepository: wishlistRepository),
            setWishlistQuantity: SetWishlistQuantityUseCase(repository: wishlistRepository)
        )

        await viewModel.refresh()
        await viewModel.loadOnAppear()

        XCTAssertEqual(buyRepository.receivedQueries.count, 1)
    }
}
