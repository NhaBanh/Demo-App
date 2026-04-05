import Foundation

struct SyncRepositoryImp: SyncRepository {
    let localDataSource: SyncLocalDataSource
    let remoteDataSource: SellRemoteGateway

    func pendingSyncOperations() async throws -> [QueuedSellOperation] {
        try await localDataSource.pendingSyncOperations()
    }

    func pendingSyncCount() async throws -> Int {
        try await localDataSource.pendingSyncCount()
    }

    func syncPendingChanges() async throws -> [QueuedSellOperation] {
        let operations = try await localDataSource.pendingSyncOperations()
        var syncedIDs: [UUID] = []
        var syncedOperations: [QueuedSellOperation] = []
        var retryableFailureOccurred = false
        var nonRetryableFailure: Error?

        for operation in operations {
            do {
                try await sync(operation)
                syncedIDs.append(operation.id)
                syncedOperations.append(operation)
            } catch {
                if isRetryable(error) {
                    retryableFailureOccurred = true
                } else if nonRetryableFailure == nil {
                    nonRetryableFailure = error
                }
            }
        }

        try await localDataSource.removePendingOperations(ids: syncedIDs)
        if let nonRetryableFailure {
            throw nonRetryableFailure
        }
        if retryableFailureOccurred {
            throw AppError.transientNetwork("Some queued sell changes could not be synced yet.")
        }
        return syncedOperations
    }

    private func sync(_ operation: QueuedSellOperation) async throws {
        switch operation.type {
        case .create:
            guard let payload = operation.payload else { return }
            try await remoteDataSource.create(item: payload)
        case .update:
            guard let payload = operation.payload else { return }
            try await remoteDataSource.update(item: payload)
        case .delete:
            try await remoteDataSource.delete(itemID: operation.itemID)
        }
    }

    private func isRetryable(_ error: Error) -> Bool {
        TransientErrorClassifier.isRetryableNetworkFailure(error)
    }
}
