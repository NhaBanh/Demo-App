import Foundation

@MainActor
struct WishlistRepositoryImp: WishlistRepository {
    let localDataSource: WishlistLocalDataSource
    let remoteDataSource: WishlistRemoteDataSource

    private var snapshotRefresher: WishlistSnapshotRefresher {
        WishlistSnapshotRefresher(
            localDataSource: localDataSource,
            remoteDataSource: remoteDataSource,
            snapshotResolver: WishlistSnapshotResolver()
        )
    }

    func wishlistRecords() throws -> [WishlistItemRecord] {
        try localDataSource.wishlistRecords()
    }

    func setQuantity(for item: BuyItem, quantity: Int) throws -> Int {
        try localDataSource.setQuantity(for: item, quantity: quantity)
    }

    func refreshSnapshots() async throws {
        try await snapshotRefresher.refresh()
    }
}
