import Foundation

struct SQLiteSyncLocalDataSource: SyncLocalDataSource {
    let store: SQLiteSellStore

    func pendingSyncOperations() async throws -> [QueuedSellOperation] {
        try await store.fetchPendingOperations()
    }

    func removePendingOperations(ids: [UUID]) async throws {
        try await store.clearPendingSales(ids: ids)
    }

    func pendingSyncCount() async throws -> Int {
        try await store.totalPendingCount()
    }
}
