import Foundation

/// Loads the Buy catalog by combining remote items with the local wishlist state.
struct LoadBuyCatalogUseCase {
    let buyRepository: BuyRepository
    let wishlistRepository: WishlistRepository

    /// Returns the final list shown by the Buy feature for the given query.
    ///
    /// The remote catalog remains the source of truth for active item data and availability.
    /// Local wishlist data only enriches matching remote items with quantity.
    func execute(
        sort: BuySortOption,
        availability: BuyItemAvailability?,
        category: BuyCategory?,
        page: Int,
        pageSize: Int
    ) async throws -> BuyCatalogPage {
        let query = BuyCatalogQuery(
            sort: sort,
            availability: availability,
            category: category,
            page: page,
            pageSize: pageSize
        )
        let remotePage = try await buyRepository.fetchItems(query: query)
        let wishlistRecords = try wishlistRepository.wishlistRecords()
        let mergedItems = mergeItems(remoteItems: remotePage.items, wishlistRecords: wishlistRecords)
        return BuyCatalogPage(
            items: mergedItems,
            page: remotePage.page,
            pageSize: remotePage.pageSize,
            totalCount: remotePage.totalCount,
            hasMore: remotePage.hasMore
        )
    }

    /// Joins remote catalog items with locally persisted wishlist quantities.
    ///
    /// The remote catalog stays authoritative for which items are currently visible.
    private func mergeItems(
        remoteItems: [BuyItem],
        wishlistRecords: [WishlistItemRecord]
    ) -> [BuyCatalogListItem] {
        let quantitiesByID = Dictionary(
            uniqueKeysWithValues: wishlistRecords.map { ($0.item.id, $0.quantity) }
        )
        return remoteItems.map { remoteItem in
            BuyCatalogListItem(
                item: remoteItem,
                wishlistQuantity: quantitiesByID[remoteItem.id] ?? 0
            )
        }
    }
}
