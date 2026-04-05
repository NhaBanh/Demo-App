import Foundation

extension AppContainer {
    func makeToCallViewModel() -> CallViewModel {
        CallViewModel(
            repository: toCallRepository,
            connectivityMonitor: connectivityMonitor
        )
    }
}
