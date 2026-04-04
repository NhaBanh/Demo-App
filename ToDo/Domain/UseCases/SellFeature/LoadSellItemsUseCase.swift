import Foundation

struct LoadSellItemsUseCase {
    let repository: ToSellRepository

    func execute(query: SellItemsQuery) async throws -> SellItemsPage {
        try await repository.fetchItems(query: query)
    }
}
