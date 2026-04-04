import Foundation

struct SQLiteSellMutationServiceImp: SellMutationService {
    let store: SQLiteSellStore

    func create(name: String, askingPrice: Decimal, quantity: Int, notes: String) async throws -> SellItem {
        let now = Date.now
        let item = SellItem(
            id: UUID(),
            name: name,
            askingPrice: askingPrice,
            quantity: quantity,
            notes: notes,
            isSold: false,
            createdAt: now,
            updatedAt: now
        )
        try await store.insertSellItemAndQueueCreate(item)
        return item
    }

    func update(_ item: SellItem) async throws -> SellItem {
        let updated = SellItem(
            id: item.id,
            name: item.name,
            askingPrice: item.askingPrice,
            quantity: item.quantity,
            notes: item.notes,
            isSold: item.isSold,
            createdAt: item.createdAt,
            updatedAt: .now
        )
        try await store.updateSellItemAndQueue(updated, type: .update)
        return updated
    }

    func delete(ids: [UUID]) async throws -> [SellItem] {
        let items = try await store.fetchSellItems(ids: ids)
        try await store.deleteSellItemsAndQueue(items)
        return items
    }

    func markSold(itemID: UUID) async throws {
        try await store.markItemSold(itemID)
    }
}
