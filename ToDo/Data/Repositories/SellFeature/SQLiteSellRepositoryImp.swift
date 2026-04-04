import Foundation

struct SQLiteSellRepositoryImp: ToSellRepository {
    let store: SQLiteSellStore

    func fetchItems(query: SellItemsQuery) async throws -> SellItemsPage {
        try await store.fetchSellItems(query: query)
    }

    func fetchItem(id: UUID) async throws -> SellItem? {
        try await store.fetchSellItem(id: id)
    }

    func restore(items: [SellItem]) async throws {
        try await store.upsertSellItems(items)
    }

    func upsert(items: [SellItem]) async throws {
        try await store.upsertSellItems(items)
    }

    func totalCount() async throws -> Int {
        try await store.totalSellCount()
    }
}
