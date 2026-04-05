import Foundation

struct SQLiteSellLocalDataSource: SellLocalDataSource, SellRepository {
    let store: SQLiteSellStore

    func fetchItems(query: SellItemsQuery) async throws -> SellItemsPage {
        try await store.fetchSellItems(query: query)
    }

    func fetchItem(id: UUID) async throws -> SellItem? {
        try await store.fetchSellItem(id: id)
    }

    func create(_ item: SellItem) async throws -> SellItem {
        try await store.insertSellItemAndQueueCreate(item)
        return item
    }

    func update(_ item: SellItem) async throws -> SellItem {
        try await store.updateSellItemAndQueue(item, type: .update)
        return item
    }

    func delete(ids: [UUID]) async throws -> [SellItem] {
        let items = try await store.fetchSellItems(ids: ids)
        try await store.deleteSellItemsAndQueue(items)
        return items
    }

    func restore(items: [SellItem]) async throws {
        try await store.upsertSellItems(items)
    }

    func totalCount() async throws -> Int {
        try await store.totalSellCount()
    }
}
