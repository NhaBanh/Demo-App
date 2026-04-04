import Foundation

/// Loads the To Buy catalog by combining remote items with the local wishlist state.
struct LoadToBuyCatalogUseCase {
    let buyRepository: BuyRepository
    let wishlistRepository: WishlistRepository

    /// Returns the final list shown by the To Buy feature for the given query.
    ///
    /// The remote catalog remains the source of truth for active item data and availability.
    /// If a wishlisted item no longer exists in the remote catalog, the locally persisted item
    /// is still surfaced as ``BuyItemAvailability/removedFromCatalog`` so the user does not lose
    /// wishlist context.
    func execute(filter: String, sort: BuySortOption) async throws -> [ToBuyListItem] {
        let query = ToBuyCatalogQuery(searchText: filter, sort: sort)
        let remoteItems = try await buyRepository.fetchItems(query: query)
        let wishlistRecords = try wishlistRepository.wishlistRecords()
        let mergedItems = mergeItems(remoteItems: remoteItems, wishlistRecords: wishlistRecords)
        let filteredItems = filterItems(mergedItems, by: filter)
        return sortItems(filteredItems, by: sort)
    }

    /// Joins remote catalog items with locally persisted wishlist quantities.
    ///
    /// Remote items are preferred when present. Wishlist-only records are appended as
    /// ``BuyItemAvailability/removedFromCatalog`` entries.
    private func mergeItems(
        remoteItems: [BuyItem],
        wishlistRecords: [WishlistItemRecord]
    ) -> [ToBuyListItem] {
        let remoteIDs = Set(remoteItems.map(\.id))
        let quantitiesByID = Dictionary(
            uniqueKeysWithValues: wishlistRecords.map { ($0.item.id, $0.quantity) }
        )
        let mergedRemoteItems = remoteItems.map { remoteItem in
            ToBuyListItem(
                item: remoteItem,
                wishlistQuantity: quantitiesByID[remoteItem.id] ?? 0
            )
        }

        let wishlistOnlyItems = wishlistRecords.compactMap { record -> ToBuyListItem? in
            guard !remoteIDs.contains(record.item.id), record.quantity > 0 else { return nil }

            return ToBuyListItem(
                item: BuyItem(
                    id: record.item.id,
                    title: record.item.title,
                    detail: record.item.detail,
                    price: record.item.price,
                    category: record.item.category,
                    availability: .removedFromCatalog
                ),
                wishlistQuantity: record.quantity
            )
        }

        return mergedRemoteItems + wishlistOnlyItems
    }

    /// Filters the merged list using the user's search text.
    private func filterItems(_ items: [ToBuyListItem], by filter: String) -> [ToBuyListItem] {
        let trimmedFilter = filter.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedFilter.isEmpty else { return items }

        return items.filter {
            $0.item.title.localizedCaseInsensitiveContains(trimmedFilter) ||
            $0.item.detail.localizedCaseInsensitiveContains(trimmedFilter)
        }
    }

    /// Sorts the merged list by availability first, then applies the selected catalog sort
    /// within each availability group.
    private func sortItems(_ items: [ToBuyListItem], by sort: BuySortOption) -> [ToBuyListItem] {
        items.sorted { lhs, rhs in
            let availabilityComparison = availabilityRank(for: lhs.item.availability) - availabilityRank(for: rhs.item.availability)
            if availabilityComparison != 0 {
                return availabilityComparison < 0
            }

            switch sort {
            case .title:
                return lhs.item.title.localizedCaseInsensitiveCompare(rhs.item.title) == .orderedAscending
            case .priceLowToHigh:
                if lhs.item.price == rhs.item.price {
                    return lhs.item.title.localizedCaseInsensitiveCompare(rhs.item.title) == .orderedAscending
                }
                return lhs.item.price < rhs.item.price
            case .priceHighToLow:
                if lhs.item.price == rhs.item.price {
                    return lhs.item.title.localizedCaseInsensitiveCompare(rhs.item.title) == .orderedAscending
                }
                return lhs.item.price > rhs.item.price
            }
        }
    }

    private func availabilityRank(for availability: BuyItemAvailability) -> Int {
        switch availability {
        case .available:
            0
        case .outOfStock:
            1
        case .removedFromCatalog:
            2
        }
    }
}
