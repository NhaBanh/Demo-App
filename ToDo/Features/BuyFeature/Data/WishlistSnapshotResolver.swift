import Foundation

struct WishlistSnapshotResolver {
    func resolve(record: WishlistItemRecord, remoteItem: BuyItem?) -> BuyItem {
        guard let remoteItem else {
            return BuyItem(
                id: record.item.id,
                title: record.item.title,
                detail: record.item.detail,
                price: record.item.price,
                category: record.item.category,
                availability: .removedFromCatalog,
                availableQuantity: 0
            )
        }

        return remoteItem
    }
}
