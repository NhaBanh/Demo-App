import Foundation

struct LoadPendingSellSyncOperationsUseCase {
    let repository: SellSyncRepository

    func execute() async throws -> [PendingSellSyncOperation] {
        try await repository.pendingOperations()
    }
}
