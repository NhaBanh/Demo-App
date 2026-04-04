import Foundation
import SwiftData

@MainActor
struct SwiftDataWishlistRepositoryImp: WishlistRepository {
    let modelContainer: ModelContainer

    func wishlistRecords() throws -> [WishlistItemRecord] {
        let context = ModelContext(modelContainer)
        let entries = try context.fetch(FetchDescriptor<WishlistEntry>())
        return entries.compactMap { entry in
            guard let category = BuyCategory(rawValue: entry.category) else { return nil }
            return WishlistItemRecord(
                item: BuyItem(
                    id: entry.id,
                    title: entry.title,
                    detail: entry.detail,
                    price: entry.price,
                    category: category,
                    availability: .removedFromCatalog
                ),
                quantity: entry.quantity,
                createdAt: entry.createdAt
            )
        }
    }

    func setQuantity(for item: BuyItem, quantity: Int) throws -> Int {
        let normalizedQuantity = max(0, quantity)
        let context = ModelContext(modelContainer)
        let id = item.id
        let predicate = #Predicate<WishlistEntry> { $0.id == id }
        let descriptor = FetchDescriptor<WishlistEntry>(predicate: predicate)
        if let existing = try context.fetch(descriptor).first {
            if normalizedQuantity == 0 {
                context.delete(existing)
            } else {
                existing.title = item.title
                existing.detail = item.detail
                existing.price = item.price
                existing.category = item.category.rawValue
                existing.quantity = normalizedQuantity
            }
            try context.save()
            return normalizedQuantity
        } else {
            guard normalizedQuantity > 0 else { return 0 }
            context.insert(
                WishlistEntry(
                    id: item.id,
                    title: item.title,
                    detail: item.detail,
                    price: item.price,
                    category: item.category.rawValue,
                    quantity: normalizedQuantity
                )
            )
            try context.save()
            return normalizedQuantity
        }
    }
}
