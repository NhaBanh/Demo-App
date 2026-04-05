import Foundation

struct SellAmountUseCase {
    let repository: SellInventoryReader & SellInventoryWriter

    func execute(itemID: UUID, amount: Int) async throws -> SellItem {
        guard let existing = try await repository.fetchItem(id: itemID) else {
            throw AppError.persistence("Sell item could not be found.")
        }

        try SellItemValidation.validateSell(
            amount: amount,
            availableQuantity: existing.quantity,
            status: existing.status
        )

        let updatedItem = SellItem(
            id: existing.id,
            title: existing.title,
            askingPrice: existing.askingPrice,
            quantity: existing.quantity - amount,
            detail: existing.detail,
            status: existing.status,
            createdAt: existing.createdAt,
            updatedAt: .now
        )

        return try await repository.update(updatedItem)
    }
}
