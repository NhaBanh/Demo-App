import Foundation

extension AppContainer {
    func makeToBuyViewModel() -> ToBuyViewModel {
        ToBuyViewModel(
            loadItems: LoadToBuyCatalogUseCase(
                buyRepository: buyRepository,
                wishlistRepository: wishlistRepository
            ),
            updateWishlistQuantity: UpdateWishlistQuantityUseCase(repository: wishlistRepository)
        )
    }
}
