import Foundation

struct LoadPendingSyncItemsUseCase {
    let repository: SellSyncQueueRepository

    func execute() async throws -> [PendingSale] {
        try await repository.pendingSales()
    }
}
