import Foundation

@MainActor
struct WishlistSnapshotRefresher {
    let localDataSource: WishlistLocalDataSource
    let remoteDataSource: WishlistRemoteDataSource
    let snapshotResolver: WishlistSnapshotResolver

    func refresh() async throws {
        let records = try localDataSource.wishlistRecords()
        let itemIDs = records.map(\.item.id)
        guard !itemIDs.isEmpty else { return }

        let remoteItems = try await remoteDataSource.fetchItems(ids: itemIDs)
        let remoteItemsByID = Dictionary(uniqueKeysWithValues: remoteItems.map { ($0.id, $0) })

        for record in records {
            let fallbackRemoteItem: BuyItem?
            if remoteItemsByID[record.item.id] == nil {
                fallbackRemoteItem = try await remoteDataSource.fetchItem(
                    title: record.item.title,
                    category: record.item.category
                )
            } else {
                fallbackRemoteItem = nil
            }

            let latestItem = snapshotResolver.resolve(
                record: record,
                remoteItem: remoteItemsByID[record.item.id] ?? fallbackRemoteItem
            )
            _ = try localDataSource.setQuantity(for: latestItem, quantity: record.quantity)
        }
    }
}
