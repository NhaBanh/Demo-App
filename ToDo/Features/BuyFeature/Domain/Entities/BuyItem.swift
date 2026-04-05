import Foundation

struct BuyItem: Identifiable, Equatable, Hashable {
    let id: UUID
    let title: String
    let detail: String
    let price: Decimal
    let category: BuyCategory
    let availability: BuyItemAvailability
    let availableQuantity: Int
}

enum BuyItemAvailability: String, Equatable, Hashable {
    case available
    case outOfStock
    case removedFromCatalog
}

enum BuyCategory: String, CaseIterable, Codable {
    case office
    case hardware
    case household
}
