import Foundation

struct UpdateSellItemUseCase {
    let repository: SellInventoryReader & SellInventoryWriter

    func execute(_ item: SellItem) async throws -> SellItem {
        guard let existing = try await repository.fetchItem(id: item.id) else {
            throw AppError.persistence("Sell item could not be found.")
        }

        let normalizedItem = SellItem(
            id: item.id,
            title: SellItemValidation.normalizedTitle(item.title),
            askingPrice: item.askingPrice,
            quantity: item.quantity,
            detail: SellItemValidation.normalizedDetail(item.detail),
            status: item.status,
            createdAt: item.createdAt,
            updatedAt: .now
        )

        try SellItemValidation.validateUpdate(current: existing, updated: normalizedItem)

        return try await repository.update(normalizedItem)
    }
}
