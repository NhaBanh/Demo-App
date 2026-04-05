import Foundation
import SwiftData

@Model
final class WishlistSwiftDataModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var detail: String
    var price: Decimal
    var category: String
    var availability: String
    var availableQuantity: Int
    var quantity: Int
    var createdAt: Date

    init(
        id: UUID,
        title: String,
        detail: String,
        price: Decimal,
        category: String,
        availability: String,
        availableQuantity: Int,
        quantity: Int,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.price = price
        self.category = category
        self.availability = availability
        self.availableQuantity = availableQuantity
        self.quantity = quantity
        self.createdAt = createdAt
    }
}
