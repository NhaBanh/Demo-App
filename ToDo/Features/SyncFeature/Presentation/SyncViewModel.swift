import Combine
import Foundation

struct SessionSyncedOperation: Identifiable, Equatable {
    let operation: QueuedSellOperation
    let syncedAt: Date

    var id: String {
        "\(operation.id.uuidString)-\(syncedAt.timeIntervalSinceReferenceDate)"
    }
}

@MainActor
final class SyncViewModel: ObservableObject {
    @Published private(set) var queuedOperations: [QueuedSellOperation] = []
    @Published private(set) var successfulOperations: [SessionSyncedOperation] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSyncing = false
    @Published var toastMessage: String?
    @Published var errorMessage: String?

    private let repository: SyncRepository
    private let syncOrchestrator: SyncOrchestrator
    private var cancellables = Set<AnyCancellable>()

    init(
        repository: SyncRepository,
        syncOrchestrator: SyncOrchestrator
    ) {
        self.repository = repository
        self.syncOrchestrator = syncOrchestrator
        bindSyncUpdates()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            queuedOperations = try await repository.pendingSyncOperations()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func syncNow() async {
        isSyncing = true
        defer { isSyncing = false }

        let count = await syncOrchestrator.trigger(.manual) ?? 0
        toastMessage = manualToastMessage(for: count)
        await refresh()
    }

    private func bindSyncUpdates() {
        syncOrchestrator.completionPublisher
            .sink { [weak self] event in
                guard let self else { return }
                let syncedAt = Date.now
                let completedOperations = event.syncedOperations.map {
                    SessionSyncedOperation(operation: $0, syncedAt: syncedAt)
                }
                self.successfulOperations.insert(contentsOf: completedOperations, at: 0)
                if event.trigger != .manual {
                    self.toastMessage = automaticToastMessage(for: event.syncedCount)
                }
                Task { @MainActor in
                    await self.refresh()
                }
            }
            .store(in: &cancellables)
    }

    private func manualToastMessage(for syncedCount: Int) -> String {
        syncedCount > 0 ? successToastMessage(for: syncedCount) : "Sync requested."
    }

    private func automaticToastMessage(for syncedCount: Int) -> String? {
        syncedCount > 0 ? successToastMessage(for: syncedCount) : nil
    }

    private func successToastMessage(for syncedCount: Int) -> String {
        "Synced \(syncedCount) sell change(s)."
    }
}
