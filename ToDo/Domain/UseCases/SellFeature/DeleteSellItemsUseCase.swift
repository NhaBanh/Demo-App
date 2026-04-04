import Foundation

struct DeleteSellItemsUseCase {
    let mutationService: SellMutationService

    func execute(ids: [UUID]) async throws -> [SellItem] {
        try await mutationService.delete(ids: ids)
    }
}
