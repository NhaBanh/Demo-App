import Foundation

struct LoadWishlistResult {
    let initialItems: [WishlistItemRecord]
    let refreshedItemsTask: Task<[WishlistItemRecord]?, Never>?
}

struct LoadWishlistUseCase {
    let repository: WishlistRepository

    func execute() async throws -> LoadWishlistResult {
        let initialItems = try sortedRecords()
        let refreshedItemsTask: Task<[WishlistItemRecord]?, Never>? = initialItems.isEmpty ? nil : Task { @MainActor in
            do {
                try await repository.refreshSnapshots()
                return try sortedRecords()
            } catch {
                return nil
            }
        }

        return LoadWishlistResult(
            initialItems: initialItems,
            refreshedItemsTask: refreshedItemsTask
        )
    }

    private func sortedRecords() throws -> [WishlistItemRecord] {
        try repository.wishlistRecords()
            .sorted(by: compareRecords)
    }

    private func compareRecords(_ lhs: WishlistItemRecord, _ rhs: WishlistItemRecord) -> Bool {
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt > rhs.createdAt
        }
        return lhs.item.title.localizedCaseInsensitiveCompare(rhs.item.title) == .orderedAscending
    }
}
