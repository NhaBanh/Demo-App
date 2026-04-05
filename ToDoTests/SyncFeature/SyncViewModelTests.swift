import XCTest
@testable import ToDo

@MainActor
final class SyncViewModelTests: XCTestCase {
    func testRefreshLoadsQueuedOperations() async {
        let queueItem = QueuedSellOperation.fixture()
        let syncRepository = SyncRepositoryFake()
        syncRepository.pendingOperationsResult = .success([queueItem])
        let viewModel = makeViewModel(syncRepository: syncRepository, connectivity: ConnectivityMonitorFake())

        await viewModel.refresh()

        XCTAssertEqual(viewModel.queuedOperations, [queueItem])
    }

    func testSyncNowUsesManualTriggerAndSetsSyncedToast() async {
        let syncRepository = SyncRepositoryFake()
        syncRepository.syncPendingChangesResult = .success([
            .fixture(type: .create),
            .fixture(type: .update)
        ])
        let viewModel = makeViewModel(syncRepository: syncRepository, connectivity: ConnectivityMonitorFake())

        await viewModel.syncNow()

        XCTAssertEqual(syncRepository.syncPendingChangesCallCount, 1)
        XCTAssertEqual(viewModel.toastMessage, "Synced 2 sell change(s).")
        XCTAssertEqual(viewModel.successfulOperations.count, 2)
    }

    private func makeViewModel(
        syncRepository: SyncRepositoryFake,
        connectivity: ConnectivityMonitorFake
    ) -> SyncViewModel {
        let orchestrator = SyncOrchestrator(
            syncRepository: syncRepository,
            connectivityMonitor: connectivity
        )
        return SyncViewModel(
            repository: syncRepository,
            syncOrchestrator: orchestrator
        )
    }
}
