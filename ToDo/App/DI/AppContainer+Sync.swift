import Foundation

extension AppContainer {
    func makeSyncViewModel() -> SyncViewModel {
        SyncViewModel(
            loadSellItems: LoadSellItemsUseCase(repository: sqliteSellRepository),
            loadPendingItems: LoadPendingSyncItemsUseCase(repository: sellSyncQueueRepository),
            markItemSold: MarkItemSoldUseCase(mutationService: sellMutationService),
            syncPendingSellOperations: makeSyncPendingSellOperationsUseCase()
        )
    }

    func makeLoadPendingSellSyncOperationsUseCase() -> LoadPendingSellSyncOperationsUseCase {
        LoadPendingSellSyncOperationsUseCase(repository: sellSyncRepository)
    }

    func makeSyncPendingSellOperationsUseCase() -> SyncPendingSellOperationsUseCase {
        SyncPendingSellOperationsUseCase(repository: sellSyncRepository)
    }
}
