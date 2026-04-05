import Foundation

struct RemoteInventoryItemDTO: Codable, Equatable, Hashable {
    let id: UUID
    let title: String
    let detail: String
    let price: Decimal
    let category: BuyCategory
    let availability: RemoteBuyAvailabilityDTO
    let quantity: Int
    let status: SellItemStatus
    let createdAt: Date
    let updatedAt: Date

    nonisolated init(
        id: UUID,
        title: String,
        detail: String,
        price: Decimal,
        category: BuyCategory,
        availability: RemoteBuyAvailabilityDTO,
        quantity: Int,
        status: SellItemStatus,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.price = price
        self.category = category
        self.availability = availability
        self.quantity = quantity
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    nonisolated init(sellItem: RemoteSellItemDTO, existing: RemoteInventoryItemDTO?) {
        id = sellItem.id
        title = sellItem.title
        detail = sellItem.detail
        price = sellItem.askingPrice
        category = existing?.category ?? .household
        availability = Self.derivedAvailability(
            quantity: sellItem.quantity,
            status: sellItem.status,
            existing: existing?.availability
        )
        quantity = sellItem.quantity
        status = sellItem.status
        createdAt = existing?.createdAt ?? sellItem.createdAt
        updatedAt = sellItem.updatedAt
    }

    nonisolated func sellingOne(at date: Date) -> RemoteInventoryItemDTO {
        let nextQuantity = max(0, quantity - 1)
        return RemoteInventoryItemDTO(
            id: id,
            title: title,
            detail: detail,
            price: price,
            category: category,
            availability: Self.derivedAvailability(
                quantity: nextQuantity,
                status: status,
                existing: availability
            ),
            quantity: nextQuantity,
            status: status,
            createdAt: createdAt,
            updatedAt: date
        )
    }

    nonisolated private static func derivedAvailability(
        quantity: Int,
        status: SellItemStatus,
        existing: RemoteBuyAvailabilityDTO?
    ) -> RemoteBuyAvailabilityDTO {
        if status == .archived {
            return .removedFromCatalog
        }
        if let existing, existing == .removedFromCatalog {
            return .removedFromCatalog
        }
        return quantity > 0 ? .available : .outOfStock
    }
}
