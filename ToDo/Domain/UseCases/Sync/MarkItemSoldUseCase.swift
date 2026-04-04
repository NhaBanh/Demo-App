import Foundation

struct MarkItemSoldUseCase {
    let mutationService: SellMutationService

    func execute(itemID: UUID) async throws {
        try await mutationService.markSold(itemID: itemID)
    }
}
