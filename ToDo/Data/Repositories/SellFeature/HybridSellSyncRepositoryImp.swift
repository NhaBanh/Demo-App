import Foundation

struct HybridSellSyncRepositoryImp: SellSyncRepository {
    let queueRepository: SellSyncQueueRepository
    let remoteRepository: SellRemoteRepository

    func pendingOperations() async throws -> [PendingSellSyncOperation] {
        try await queueRepository.pendingOperations()
    }

    func syncPendingOperations() async throws -> Int {
        let operations = try await pendingOperations()
        var syncedIDs: [UUID] = []

        for operation in operations {
            do {
                try await sync(operation)
                syncedIDs.append(operation.id)
            } catch {
                continue
            }
        }

        try await queueRepository.removePendingOperations(ids: syncedIDs)
        return syncedIDs.count
    }

    private func sync(_ operation: PendingSellSyncOperation) async throws {
        switch operation.type {
        case .create:
            guard let payload = operation.payload else { return }
            try await remoteRepository.create(item: payload)
        case .update:
            guard let payload = operation.payload else { return }
            try await remoteRepository.update(item: payload)
        case .delete:
            try await remoteRepository.delete(itemID: operation.itemID)
        case .markSold:
            try await remoteRepository.markSold(itemID: operation.itemID)
        }
    }
}
