import Foundation

protocol SellInventoryReader {
    func fetchItems(query: SellItemsQuery) async throws -> SellItemsPage
    func fetchItem(id: UUID) async throws -> SellItem?
    func totalCount() async throws -> Int
}

protocol SellInventoryWriter {
    func create(_ item: SellItem) async throws -> SellItem
    func update(_ item: SellItem) async throws -> SellItem
    func delete(ids: [UUID]) async throws -> [SellItem]
    func restore(items: [SellItem]) async throws
}

protocol SellRepository: SellInventoryReader, SellInventoryWriter {}
