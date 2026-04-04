import Foundation

struct SyncPendingSellOperationsUseCase {
    let repository: SellSyncRepository

    func execute() async throws -> Int {
        try await repository.syncPendingOperations()
    }
}
