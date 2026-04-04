import Foundation

struct UpdateSellItemUseCase {
    let repository: ToSellRepository
    let mutationService: SellMutationService

    func execute(_ item: SellItem) async throws -> SellItem {
        guard let existing = try await repository.fetchItem(id: item.id) else {
            throw AppError.persistence("Sell item could not be found.")
        }

        let normalizedItem = SellItem(
            id: item.id,
            name: SellItemValidation.normalizedName(item.name),
            askingPrice: item.askingPrice,
            quantity: item.quantity,
            notes: SellItemValidation.normalizedNotes(item.notes),
            isSold: item.isSold,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt
        )

        try SellItemValidation.validateUpdate(current: existing, updated: normalizedItem)

        return try await mutationService.update(normalizedItem)
    }
}
