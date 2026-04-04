import Foundation

struct CreateSellItemUseCase {
    let mutationService: SellMutationService

    func execute(name: String, askingPrice: Decimal, quantity: Int, notes: String) async throws -> SellItem {
        let normalizedName = SellItemValidation.normalizedName(name)
        let normalizedNotes = SellItemValidation.normalizedNotes(notes)
        try SellItemValidation.validate(
            name: normalizedName,
            askingPrice: askingPrice,
            quantity: quantity,
            notes: normalizedNotes
        )

        return try await mutationService.create(
            name: normalizedName,
            askingPrice: askingPrice,
            quantity: quantity,
            notes: normalizedNotes
        )
    }
}
