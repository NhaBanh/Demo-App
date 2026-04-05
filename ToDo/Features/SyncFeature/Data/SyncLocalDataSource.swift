import Foundation

protocol SyncLocalDataSource {
    func pendingSyncOperations() async throws -> [QueuedSellOperation]
    func pendingSyncCount() async throws -> Int
    func removePendingOperations(ids: [UUID]) async throws
}
