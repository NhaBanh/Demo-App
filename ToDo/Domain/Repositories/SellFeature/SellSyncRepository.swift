import Foundation

protocol SellSyncRepository {
    func pendingOperations() async throws -> [PendingSellSyncOperation]
    func syncPendingOperations() async throws -> Int
}
