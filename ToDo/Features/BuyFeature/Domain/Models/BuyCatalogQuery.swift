import Foundation

enum BuyAvailabilityFilter: String, CaseIterable, Identifiable {
    case all
    case available
    case outOfStock
    case removedFromCatalog

    var id: String { rawValue }

    var itemAvailability: BuyItemAvailability? {
        switch self {
        case .all:
            nil
        case .available:
            .available
        case .outOfStock:
            .outOfStock
        case .removedFromCatalog:
            .removedFromCatalog
        }
    }
}

enum BuyCategoryFilter: String, CaseIterable, Identifiable {
    case all
    case office
    case hardware
    case household

    var id: String { rawValue }

    var category: BuyCategory? {
        switch self {
        case .all:
            nil
        case .office:
            .office
        case .hardware:
            .hardware
        case .household:
            .household
        }
    }
}

enum BuySortOption: String, CaseIterable, Identifiable {
    case title
    case priceLowToHigh
    case priceHighToLow

    var id: String { rawValue }
}

struct BuyCatalogQuery: Equatable, Hashable {
    let sort: BuySortOption
    let availability: BuyItemAvailability?
    let category: BuyCategory?
    let page: Int
    let pageSize: Int
}

struct BuyItemsPage: Equatable {
    let items: [BuyItem]
    let page: Int
    let pageSize: Int
    let totalCount: Int
    let hasMore: Bool
}

struct BuyCatalogPage: Equatable {
    let items: [BuyCatalogListItem]
    let page: Int
    let pageSize: Int
    let totalCount: Int
    let hasMore: Bool
}
