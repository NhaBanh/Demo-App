import Foundation

struct RemoteBuyItemDTO: Codable, Equatable, Hashable {
    let id: UUID
    let title: String
    let detail: String
    let price: Decimal
    let category: BuyCategory
    let availability: RemoteBuyAvailabilityDTO

    func toDomain() -> BuyItem {
        BuyItem(
            id: id,
            title: title,
            detail: detail,
            price: price,
            category: category,
            availability: availability.toDomain()
        )
    }
}

enum RemoteBuyAvailabilityDTO: String, Codable, Equatable, Hashable {
    case available
    case outOfStock
    case removedFromCatalog

    func toDomain() -> BuyItemAvailability {
        switch self {
        case .available:
            .available
        case .outOfStock:
            .outOfStock
        case .removedFromCatalog:
            .removedFromCatalog
        }
    }
}
