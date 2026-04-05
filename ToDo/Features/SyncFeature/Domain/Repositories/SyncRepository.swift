import Foundation

protocol SyncRepository {
    func pendingSyncOperations() async throws -> [QueuedSellOperation]
    func pendingSyncCount() async throws -> Int
    func syncPendingChanges() async throws -> [QueuedSellOperation]
}
