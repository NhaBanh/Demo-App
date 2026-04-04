import Combine
import Foundation
import Network

/// Describes a service that exposes the app's current network reachability state.
///
/// Use this abstraction instead of binding features directly to `NWPathMonitor`
/// so connectivity-aware behavior can be mocked, tested, or replaced at the
/// composition root.
protocol ConnectivityMonitoring: AnyObject {
    /// A synchronous snapshot of the most recent connectivity state.
    var isConnected: Bool { get }

    /// A publisher that emits whenever connectivity changes.
    ///
    /// The emitted value is `true` when the network is currently reachable and
    /// `false` when the app should treat the connection as unavailable.
    var connectivityPublisher: AnyPublisher<Bool, Never> { get }
}

/// Default `ConnectivityMonitoring` implementation backed by `NWPathMonitor`.
///
/// This type converts path updates into a simple boolean stream that higher
/// layers can consume without importing `Network` directly.
final class NetworkConnectivityMonitor: ConnectivityMonitoring {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ToDo.NetworkConnectivityMonitor")
    private let subject = CurrentValueSubject<Bool, Never>(true)

    /// The latest known connectivity state reported by `NWPathMonitor`.
    var isConnected: Bool {
        subject.value
    }

    /// A publisher of connectivity updates derived from `NWPathMonitor`.
    var connectivityPublisher: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    /// Creates and starts a live network connectivity monitor.
    init() {
        monitor.pathUpdateHandler = { [subject] path in
            subject.send(path.status == .satisfied)
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
