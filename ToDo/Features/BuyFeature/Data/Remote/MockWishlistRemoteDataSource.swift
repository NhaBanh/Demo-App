import Foundation

@MainActor
struct MockWishlistRemoteDataSource: WishlistRemoteDataSource {
    let server: MockInventoryServer

    func fetchItems(ids: [UUID]) async throws -> [BuyItem] {
        let remoteItems = try await server.fetchBuyItems(ids: ids)
        return remoteItems.map { $0.toDomain() }
    }

    func fetchItem(title: String, category: BuyCategory) async throws -> BuyItem? {
        try await server.fetchBuyItem(title: title, category: category)?.toDomain()
    }
}
