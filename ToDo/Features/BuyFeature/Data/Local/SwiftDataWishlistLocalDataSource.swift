import Foundation
import SwiftData

@MainActor
struct SwiftDataWishlistLocalDataSource: WishlistLocalDataSource {
    let modelContainer: ModelContainer

    func wishlistRecords() throws -> [WishlistItemRecord] {
        let context = ModelContext(modelContainer)
        let entries = try context.fetch(FetchDescriptor<WishlistSwiftDataModel>())

        return entries.compactMap { entry -> WishlistItemRecord? in
            guard
                let category = BuyCategory(rawValue: entry.category),
                let availability = BuyItemAvailability(rawValue: entry.availability)
            else {
                return nil
            }
            return WishlistItemRecord(
                item: BuyItem(
                    id: entry.id,
                    title: entry.title,
                    detail: entry.detail,
                    price: entry.price,
                    category: category,
                    availability: availability,
                    availableQuantity: entry.availableQuantity
                ),
                quantity: entry.quantity,
                createdAt: entry.createdAt
            )
        }
    }

    func setQuantity(for item: BuyItem, quantity: Int) throws -> Int {
        let normalizedQuantity = max(0, quantity)
        let context = ModelContext(modelContainer)
        let entries = try context.fetch(FetchDescriptor<WishlistSwiftDataModel>())

        if let existing = findExistingEntry(for: item, in: entries) {
            if normalizedQuantity == 0 {
                context.delete(existing)
            } else {
                existing.title = item.title
                existing.detail = item.detail
                existing.price = item.price
                existing.category = item.category.rawValue
                existing.availability = item.availability.rawValue
                existing.availableQuantity = item.availableQuantity
                existing.quantity = normalizedQuantity
                existing.id = item.id
            }
            try context.save()
            return normalizedQuantity
        } else {
            guard normalizedQuantity > 0 else { return 0 }
            context.insert(
                WishlistSwiftDataModel(
                    id: item.id,
                    title: item.title,
                    detail: item.detail,
                    price: item.price,
                    category: item.category.rawValue,
                    availability: item.availability.rawValue,
                    availableQuantity: item.availableQuantity,
                    quantity: normalizedQuantity
                )
            )
            try context.save()
            return normalizedQuantity
        }
    }

    private func findExistingEntry(
        for item: BuyItem,
        in entries: [WishlistSwiftDataModel]
    ) -> WishlistSwiftDataModel? {
        return entries.first {
            $0.id == item.id ||
            ($0.title == item.title && $0.category == item.category.rawValue)
        }
    }
}
