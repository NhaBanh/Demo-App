import Foundation

struct RemoteBuyRepositoryImp: BuyRepository {
    let server: MockInventoryServer

    func fetchItems(query: ToBuyCatalogQuery) async throws -> [BuyItem] {
        try await server.fetchBuyItems(query: query).map { $0.toDomain() }
    }

    func totalCount() async throws -> Int {
        await server.totalBuyItemCount()
    }
}
