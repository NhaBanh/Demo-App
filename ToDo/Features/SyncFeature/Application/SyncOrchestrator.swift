import Combine
import Foundation

@MainActor
final class SyncOrchestrator {
    struct CompletionEvent {
        let trigger: Trigger
        let syncedOperations: [QueuedSellOperation]

        var syncedCount: Int {
            syncedOperations.count
        }
    }

    enum Trigger {
        case connectivityRegained
        case manual
        case backgroundTask
        case retry
    }

    private let syncRepository: SyncRepository
    private let connectivityMonitor: ConnectivityMonitoring
    private let userFacingRetryCoordinator: AutoRetryCoordinator
    private let backgroundRetryCoordinator: AutoRetryCoordinator

    let completionPublisher = PassthroughSubject<CompletionEvent, Never>()

    private var isSyncRunning = false
    private var hasPendingTrigger = false
    private var cancellables = Set<AnyCancellable>()

    init(
        syncRepository: SyncRepository,
        connectivityMonitor: ConnectivityMonitoring
    ) {
        self.syncRepository = syncRepository
        self.connectivityMonitor = connectivityMonitor
        userFacingRetryCoordinator = AutoRetryCoordinator(
            connectivityMonitor: connectivityMonitor,
            policyPreset: .userFacing,
            isRetryableError: Self.isRetryableSyncError,
            statusHandler: { _ in }
        )
        backgroundRetryCoordinator = AutoRetryCoordinator(
            connectivityMonitor: connectivityMonitor,
            policyPreset: .backgroundSync,
            isRetryableError: Self.isRetryableSyncError,
            statusHandler: { _ in }
        )
        bindConnectivity()
    }

    @discardableResult
    func trigger(_ source: Trigger) async -> Int? {
        if !isRetryTrigger(source) {
            retryCoordinator(for: source).reset()
        }

        guard connectivityMonitor.isConnected else {
            hasPendingTrigger = true
            return nil
        }

        guard !isSyncRunning else {
            hasPendingTrigger = true
            return nil
        }

        return await runSyncLoop(trigger: source)
    }

    private func bindConnectivity() {
        connectivityMonitor.connectivityPublisher
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] isConnected in
                guard let self, isConnected else { return }
                Task {
                    await self.trigger(.connectivityRegained)
                }
            }
            .store(in: &cancellables)
    }

    private func runSyncLoop(trigger source: Trigger) async -> Int? {
        isSyncRunning = true
        defer { isSyncRunning = false }

        var firstSyncedOperations: [QueuedSellOperation]?

        while connectivityMonitor.isConnected {
            hasPendingTrigger = false

            do {
                let syncedOperations = try await syncRepository.syncPendingChanges()
                retryCoordinator(for: source).reset()
                if firstSyncedOperations == nil {
                    firstSyncedOperations = syncedOperations
                }
            } catch {
                let retryCoordinator = retryCoordinator(for: source)
                let retryTrigger = retryTrigger(for: source)
                let accepted = retryCoordinator.handleFailure(error) { [weak self] in
                    guard let self else { return }
                    await self.trigger(retryTrigger)
                }
                if !accepted {
                    retryCoordinator.reset()
                }
                break
            }

            guard hasPendingTrigger else { break }
        }

        if let firstSyncedOperations {
            completionPublisher.send(.init(trigger: source, syncedOperations: firstSyncedOperations))
        }

        return firstSyncedOperations?.count
    }

    private static func isRetryableSyncError(_ error: Error) -> Bool {
        TransientErrorClassifier.isRetryableNetworkFailure(error)
    }

    private func retryCoordinator(for source: Trigger) -> AutoRetryCoordinator {
        switch retryPolicyPreset(for: source) {
        case .userFacing:
            userFacingRetryCoordinator
        case .backgroundSync:
            backgroundRetryCoordinator
        }
    }

    private func retryTrigger(for source: Trigger) -> Trigger {
        switch retryPolicyPreset(for: source) {
        case .userFacing:
            .retry
        case .backgroundSync:
            .backgroundTask
        }
    }

    private func retryPolicyPreset(for source: Trigger) -> AutoRetryCoordinator.RetryPolicyPreset {
        switch source {
        case .backgroundTask:
            .backgroundSync
        case .connectivityRegained, .manual, .retry:
            .userFacing
        }
    }

    private func isRetryTrigger(_ source: Trigger) -> Bool {
        if case .retry = source {
            return true
        }
        return false
    }
}
