import Foundation

extension AppContainer {
    func makeSyncViewModel() -> SyncViewModel {
        SyncViewModel(
            repository: syncRepository,
            syncOrchestrator: syncOrchestrator
        )
    }
}
