import Foundation

protocol ToSellRepository {
    func fetchItems(query: SellItemsQuery) async throws -> SellItemsPage
    func fetchItem(id: UUID) async throws -> SellItem?
    func restore(items: [SellItem]) async throws
    func upsert(items: [SellItem]) async throws
    func totalCount() async throws -> Int
}
