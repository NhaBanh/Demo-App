import Foundation

struct ToBuyCatalogQuery: Equatable, Hashable {
    let searchText: String
    let sort: BuySortOption
}
