import Foundation

struct SellItem: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let askingPrice: Decimal
    let quantity: Int
    let notes: String
    let isSold: Bool
    let createdAt: Date
    let updatedAt: Date
}
