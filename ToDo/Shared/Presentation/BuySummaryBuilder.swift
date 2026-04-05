import Foundation

struct BuySummaryBuilder {
    let wishlistRepository: WishlistRepository

    func makeInitialSummary() -> BuySummary {
        BuySummary(
            availableCount: 0,
            outOfStockCount: 0,
            outOfCatalogCount: 0,
            wishlistCount: makeWishlistCount()
        )
    }

    func makeSummary(items: [BuyCatalogListItem]) -> BuySummary {
        let uniqueItems = uniqueItemsByID(items)
        return BuySummary(
            availableCount: uniqueItems.filter { $0.item.availability == .available }.count,
            outOfStockCount: uniqueItems.filter { $0.item.availability == .outOfStock }.count,
            outOfCatalogCount: uniqueItems.filter { $0.item.availability == .removedFromCatalog }.count,
            wishlistCount: makeWishlistCount()
        )
    }

    func makeWishlistCount() -> Int {
        (try? wishlistRepository.wishlistRecords().filter { $0.quantity > 0 }.count) ?? 0
    }

    private func uniqueItemsByID(_ items: [BuyCatalogListItem]) -> [BuyCatalogListItem] {
        var itemsByID = [UUID: BuyCatalogListItem]()
        for item in items {
            itemsByID[item.id] = item
        }
        return Array(itemsByID.values)
    }
}
