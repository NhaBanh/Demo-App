import Foundation

extension AppContainer {
    func makeHomeSummaryViewModel() -> HomeSummaryViewModel {
        HomeSummaryViewModel(
            sellRepository: sellRepository,
            syncRepository: syncRepository,
            wishlistRepository: buyWishlistRepository,
            syncOrchestrator: syncOrchestrator
        )
    }
}
