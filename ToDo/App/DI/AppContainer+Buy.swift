import Foundation

extension AppContainer {
    func makeBuyCatalogViewModel() -> BuyCatalogViewModel {
        let dependencies = buyDependencies
        return BuyCatalogViewModel(
            loadItems: dependencies.loadCatalog,
            setWishlistQuantity: dependencies.setWishlistQuantity
        )
    }

    func makeWishlistViewModel() -> WishlistViewModel {
        let dependencies = buyDependencies
        return WishlistViewModel(
            loadItems: dependencies.loadWishlist,
            setQuantity: dependencies.setWishlistQuantity
        )
    }
}
