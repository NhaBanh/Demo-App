import Foundation

@MainActor
protocol WishlistRemoteDataSource {
    func fetchItems(ids: [UUID]) async throws -> [BuyItem]
    func fetchItem(title: String, category: BuyCategory) async throws -> BuyItem?
}
