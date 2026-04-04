import Foundation

struct SQLiteSellSyncQueueRepositoryImp: SellSyncQueueRepository {
    let store: SQLiteSellStore

    func enqueueCreate(for item: SellItem) async throws {
        try await store.queuePendingOperation(type: .create, item: item, queueID: UUID())
    }

    func enqueueUpdate(for item: SellItem) async throws {
        try await store.queuePendingOperation(type: .update, item: item, queueID: UUID())
    }

    func enqueueDelete(for items: [SellItem]) async throws {
        for item in items {
            try await store.queuePendingOperation(type: .delete, item: item, queueID: UUID())
        }
    }

    func enqueueMarkSold(for item: SellItem) async throws {
        try await store.queuePendingOperation(type: .markSold, item: item, queueID: UUID())
    }

    func pendingOperations() async throws -> [PendingSellSyncOperation] {
        try await store.fetchPendingOperations()
    }

    func pendingSales() async throws -> [PendingSale] {
        try await store.fetchPendingSales()
    }

    func pendingCount() async throws -> Int {
        try await store.totalPendingCount()
    }

    func removePendingOperations(ids: [UUID]) async throws {
        try await store.clearPendingSales(ids: ids)
    }
}
