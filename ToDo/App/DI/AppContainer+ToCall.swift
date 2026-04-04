import Foundation

extension AppContainer {
    func makeToCallViewModel() -> ToCallViewModel {
        ToCallViewModel(
            loadPage: LoadToCallPageUseCase(repository: toCallRepository),
            connectivityMonitor: connectivityMonitor
        )
    }
}
