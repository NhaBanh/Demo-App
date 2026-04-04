import Foundation

protocol SellSyncQueueRepository {
    func enqueueCreate(for item: SellItem) async throws
    func enqueueUpdate(for item: SellItem) async throws
    func enqueueDelete(for items: [SellItem]) async throws
    func enqueueMarkSold(for item: SellItem) async throws
    func pendingOperations() async throws -> [PendingSellSyncOperation]
    func pendingSales() async throws -> [PendingSale]
    func pendingCount() async throws -> Int
    func removePendingOperations(ids: [UUID]) async throws
}
