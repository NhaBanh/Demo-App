import BackgroundTasks
import Foundation

@MainActor
final class SellSyncBackgroundTaskManager {
    static let taskIdentifier = "com.blmn.ToDo.sell-sync-refresh"

    private let syncOrchestrator: SyncOrchestrator

    init(syncOrchestrator: SyncOrchestrator) {
        self.syncOrchestrator = syncOrchestrator
    }

    func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let self, let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handle(refreshTask)
        }
    }

    func scheduleNextRun() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            #if DEBUG
            print("Failed to schedule sell sync background task: \(error)")
            #endif
        }
    }

    private func handle(_ task: BGAppRefreshTask) {
        scheduleNextRun()

        let worker = Task { @MainActor [weak self] in
            guard let self else { return false }
            return await self.runBackgroundSyncAttempts()
        }

        task.expirationHandler = {
            worker.cancel()
        }

        Task { @MainActor in
            let didStartSync = await worker.value
            task.setTaskCompleted(success: didStartSync)
        }
    }

    private func runBackgroundSyncAttempts() async -> Bool {
        guard !Task.isCancelled else { return false }
        return await syncOrchestrator.trigger(.backgroundTask) != nil
    }
}
