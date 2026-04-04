import Foundation

struct RemoteSellItemDTO: Codable, Equatable, Hashable {
    let id: UUID
    let name: String
    let askingPrice: Decimal
    let quantity: Int
    let notes: String
    let isSold: Bool
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID,
        name: String,
        askingPrice: Decimal,
        quantity: Int,
        notes: String,
        isSold: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.askingPrice = askingPrice
        self.quantity = quantity
        self.notes = notes
        self.isSold = isSold
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(item: SellItem) {
        id = item.id
        name = item.name
        askingPrice = item.askingPrice
        quantity = item.quantity
        notes = item.notes
        isSold = item.isSold
        createdAt = item.createdAt
        updatedAt = item.updatedAt
    }

    func toDomain() -> SellItem {
        SellItem(
            id: id,
            name: name,
            askingPrice: askingPrice,
            quantity: quantity,
            notes: notes,
            isSold: isSold,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
