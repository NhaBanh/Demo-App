import Foundation

extension AppContainer {
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(loadDashboardCounts: makeLoadDashboardCountsUseCase())
    }

    func makeLoadDashboardCountsUseCase() -> LoadDashboardCountsUseCase {
        LoadDashboardCountsUseCase(
            toCallRepository: toCallRepository,
            buyRepository: buyRepository,
            sellRepository: makeSellRepository(),
            sellSyncQueueRepository: sellSyncQueueRepository
        )
    }
}
