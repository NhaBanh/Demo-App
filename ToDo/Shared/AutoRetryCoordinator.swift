import Combine
import Foundation

/// Coordinates automatic retries for transient failures using backoff and
/// connectivity-aware recovery.
///
/// `AutoRetryCoordinator` is intended for long-lived feature flows that need to:
///
/// - classify whether a failure is retryable
/// - schedule retries with a configurable delay policy
/// - pause retries while offline
/// - retry immediately when connectivity returns
/// - surface retry status messages back to the UI layer
///
/// The feature view model remains responsible for loading screen state, while
/// this type owns the retry state machine itself.
@MainActor
final class AutoRetryCoordinator {
    /// An async operation that performs a single retry attempt.
    typealias RetryOperation = @Sendable () async -> Void

    /// Receives retry status updates suitable for presentation.
    typealias StatusHandler = @MainActor (String?) -> Void

    /// Evaluates whether a given error should enter the retry flow.
    typealias RetryableErrorEvaluator = (Error) -> Bool

    private let connectivityMonitor: ConnectivityMonitoring
    private let retrySchedule: [TimeInterval]
    private let isRetryableError: RetryableErrorEvaluator
    private let statusHandler: StatusHandler

    private var attempt = 0
    private var pendingRetry: RetryOperation?
    private var scheduledRetryTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    /// Creates a retry coordinator for a feature-specific load flow.
    ///
    /// - Parameters:
    ///   - connectivityMonitor: A service that reports current network reachability.
    ///   - retrySchedule: Delay values in seconds for successive retry attempts.
    ///     Once the schedule is exhausted, the last value is reused.
    ///   - isRetryableError: A closure that determines whether an error should be retried.
    ///   - statusHandler: A closure used to publish retry status back to the caller.
    init(
        connectivityMonitor: ConnectivityMonitoring,
        retrySchedule: [TimeInterval] = [5, 10, 20, 40, 60],
        isRetryableError: @escaping RetryableErrorEvaluator,
        statusHandler: @escaping StatusHandler
    ) {
        self.connectivityMonitor = connectivityMonitor
        self.retrySchedule = retrySchedule
        self.isRetryableError = isRetryableError
        self.statusHandler = statusHandler
        bindConnectivity()
    }

    /// Clears pending retry state and removes any currently scheduled retry.
    func reset() {
        scheduledRetryTask?.cancel()
        scheduledRetryTask = nil
        pendingRetry = nil
        attempt = 0
        statusHandler(nil)
    }

    /// Processes a failure and starts automatic retry behavior when appropriate.
    ///
    /// - Parameters:
    ///   - error: The error returned by the last attempted operation.
    ///   - retry: The async operation to invoke for each retry attempt.
    /// - Returns: `true` when the error was accepted into the retry flow,
    ///   otherwise `false`.
    func handleFailure(_ error: Error, retry: @escaping RetryOperation) -> Bool {
        guard isRetryableError(error) else {
            reset()
            return false
        }

        pendingRetry = retry
        scheduleRetryIfNeeded()
        return true
    }

    private func bindConnectivity() {
        connectivityMonitor.connectivityPublisher
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] isConnected in
                guard let self else { return }
                guard isConnected, let retry = self.pendingRetry else { return }
                self.scheduledRetryTask?.cancel()
                self.scheduledRetryTask = nil
                self.statusHandler("Connection restored. Retrying now...")
                Task {
                    await retry()
                }
            }
            .store(in: &cancellables)
    }

    private func scheduleRetryIfNeeded() {
        guard let retry = pendingRetry else { return }

        scheduledRetryTask?.cancel()
        scheduledRetryTask = nil

        guard connectivityMonitor.isConnected else {
            statusHandler("Waiting for network connection to retry.")
            return
        }

        let delay = retryDelay(for: attempt)
        attempt += 1
        statusHandler("Temporary network issue. Retrying in \(Int(delay))s...")

        scheduledRetryTask = Task {
            do {
                try await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                await retry()
            } catch {
                return
            }
        }
    }

    private func retryDelay(for attempt: Int) -> TimeInterval {
        if attempt < retrySchedule.count {
            return retrySchedule[attempt]
        }
        return 60
    }
}
