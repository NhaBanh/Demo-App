import Foundation

struct RestoreSellItemsUseCase {
    let repository: ToSellRepository

    func execute(items: [SellItem]) async throws {
        try await repository.restore(items: items)
    }
}
