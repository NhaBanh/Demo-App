import Foundation

protocol BuyRepository {
    func fetchItems(query: BuyCatalogQuery) async throws -> BuyItemsPage
    func totalCount() async throws -> Int
}
