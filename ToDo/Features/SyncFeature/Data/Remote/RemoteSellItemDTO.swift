import Foundation

struct RemoteSellItemDTO: Codable, Equatable, Hashable {
    let id: UUID
    let title: String
    let askingPrice: Decimal
    let quantity: Int
    let detail: String
    let status: SellItemStatus
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID,
        title: String,
        askingPrice: Decimal,
        quantity: Int,
        detail: String,
        status: SellItemStatus,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.askingPrice = askingPrice
        self.quantity = quantity
        self.detail = detail
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(item: SellItem) {
        id = item.id
        title = item.title
        askingPrice = item.askingPrice
        quantity = item.quantity
        detail = item.detail
        status = item.status
        createdAt = item.createdAt
        updatedAt = item.updatedAt
    }

    nonisolated init(item: RemoteInventoryItemDTO) {
        id = item.id
        title = item.title
        askingPrice = item.price
        quantity = item.quantity
        detail = item.detail
        status = item.status
        createdAt = item.createdAt
        updatedAt = item.updatedAt
    }

    func toDomain() -> SellItem {
        SellItem(
            id: id,
            title: title,
            askingPrice: askingPrice,
            quantity: quantity,
            detail: detail,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
