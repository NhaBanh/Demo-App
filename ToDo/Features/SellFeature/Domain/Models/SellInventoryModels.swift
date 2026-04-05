import Foundation

struct SellItemsQuery: Equatable {
    var status: SellItemStatusFilter = .all
    var sort: SellItemSort = .updatedAtDescending
    var page: Int = 1
    var pageSize: Int = 20
}

enum SellItemStatusFilter: Equatable {
    case all
    case available
    case soldOut
}

enum SellItemSort: Equatable {
    case updatedAtDescending
}

struct SellItemsPage: Equatable {
    let items: [SellItem]
    let page: Int
    let pageSize: Int
    let totalCount: Int
    let hasMore: Bool
}
