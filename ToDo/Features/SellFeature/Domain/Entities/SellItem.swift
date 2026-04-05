import Foundation

enum SellItemStatus: String, Codable, Equatable, Hashable {
    case active
    case archived
}

struct SellItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let title: String
    let askingPrice: Decimal
    let quantity: Int
    let detail: String
    let status: SellItemStatus
    let createdAt: Date
    let updatedAt: Date
}
