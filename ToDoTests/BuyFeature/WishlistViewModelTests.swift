import XCTest
@testable import ToDo

@MainActor
final class WishlistViewModelTests: XCTestCase {
    func testRefreshLoadsWishlistRecords() async {
        let repository = WishlistRepositoryFake()
        repository.records = [
            .fixture(
                item: .fixture(title: "Desk Lamp", availability: .available, availableQuantity: 4),
                quantity: 2,
                createdAt: Date(timeIntervalSince1970: 2)
            ),
            .fixture(
                item: .fixture(title: "Printer Ink", availability: .outOfStock, availableQuantity: 0),
                quantity: 1,
                createdAt: Date(timeIntervalSince1970: 1)
            )
        ]

        let viewModel = WishlistViewModel(
            loadItems: LoadWishlistUseCase(repository: repository),
            setQuantity: SetWishlistQuantityUseCase(repository: repository)
        )

        await viewModel.refresh()

        XCTAssertEqual(viewModel.items.count, 2)
        XCTAssertEqual(viewModel.items.map(\.item.title), ["Desk Lamp", "Printer Ink"])
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(repository.refreshSnapshotsCallCount, 1)
    }

    func testRefreshAppliesUpdatedRecordsAfterBackgroundSnapshotRefresh() async {
        let repository = WishlistRepositoryFake()
        let itemID = UUID()
        repository.records = [
            .fixture(
                item: .fixture(
                    id: itemID,
                    title: "Desk Lamp",
                    detail: "Old detail",
                    price: 20,
                    category: .household,
                    availability: .available,
                    availableQuantity: 3
                ),
                quantity: 2,
                createdAt: Date(timeIntervalSince1970: 2)
            )
        ]
        repository.refreshSnapshotsHandler = {
            repository.records = [
                .fixture(
                    item: .fixture(
                        id: itemID,
                        title: "Desk Lamp",
                        detail: "Fresh detail",
                        price: 25,
                        category: .household,
                        availability: .outOfStock,
                        availableQuantity: 0
                    ),
                    quantity: 2,
                    createdAt: Date(timeIntervalSince1970: 2)
                )
            ]
        }

        let viewModel = WishlistViewModel(
            loadItems: LoadWishlistUseCase(repository: repository),
            setQuantity: SetWishlistQuantityUseCase(repository: repository)
        )

        await viewModel.refresh()

        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.items[0].item.detail, "Fresh detail")
        XCTAssertEqual(viewModel.items[0].item.availability, .outOfStock)
    }

    func testDecrementQuantityRemovesItemWhenItReachesZero() async {
        let item = BuyItem.fixture(title: "Desk Lamp", availability: .outOfStock, availableQuantity: 0)
        let repository = WishlistRepositoryFake()
        repository.records = [.fixture(item: item, quantity: 1)]
        repository.setQuantityResult = .success(0)

        let viewModel = WishlistViewModel(
            loadItems: LoadWishlistUseCase(repository: repository),
            setQuantity: SetWishlistQuantityUseCase(repository: repository)
        )

        await viewModel.refresh()
        await viewModel.decrementQuantity(for: viewModel.items[0])

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertEqual(repository.setQuantityCalls.first?.quantity, 0)
    }

    func testIncrementQuantityRespectsAvailableStock() async {
        let item = BuyItem.fixture(title: "Desk Lamp", availability: .available, availableQuantity: 2)
        let repository = WishlistRepositoryFake()
        repository.records = [.fixture(item: item, quantity: 2)]

        let viewModel = WishlistViewModel(
            loadItems: LoadWishlistUseCase(repository: repository),
            setQuantity: SetWishlistQuantityUseCase(repository: repository)
        )

        await viewModel.refresh()
        await viewModel.incrementQuantity(for: viewModel.items[0])

        XCTAssertEqual(
            viewModel.errorMessage,
            "Wishlist quantity cannot exceed available stock (2)."
        )
    }

    func testRemoveUsesZeroQuantityUpdate() async {
        let item = BuyItem.fixture(title: "Desk Lamp", availability: .available, availableQuantity: 2)
        let repository = WishlistRepositoryFake()
        repository.records = [.fixture(item: item, quantity: 2)]
        repository.setQuantityResult = .success(0)

        let viewModel = WishlistViewModel(
            loadItems: LoadWishlistUseCase(repository: repository),
            setQuantity: SetWishlistQuantityUseCase(repository: repository)
        )

        await viewModel.refresh()
        await viewModel.remove(viewModel.items[0])

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertEqual(repository.setQuantityCalls.first?.quantity, 0)
    }

}
