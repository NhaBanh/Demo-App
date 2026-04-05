import Foundation

struct RemoteBuyRepositoryImp: BuyRepository {
    let server: MockInventoryServer

    func fetchItems(query: BuyCatalogQuery) async throws -> BuyItemsPage {
        let page = try await server.fetchBuyItems(query: query)
        return BuyItemsPage(
            items: page.items.map { $0.toDomain() },
            page: page.page,
            pageSize: page.pageSize,
            totalCount: page.totalCount,
            hasMore: page.hasMore
        )
    }

    func totalCount() async throws -> Int {
        await server.totalBuyItemCount()
    }
}
