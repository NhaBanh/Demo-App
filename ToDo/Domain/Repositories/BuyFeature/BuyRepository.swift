import Foundation

protocol BuyRepository {
    func fetchItems(query: ToBuyCatalogQuery) async throws -> [BuyItem]
    func totalCount() async throws -> Int
}
