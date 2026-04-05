import Foundation

struct CreateSellItemUseCase {
    let repository: SellInventoryWriter

    func execute(title: String, askingPrice: Decimal, quantity: Int, detail: String) async throws -> SellItem {
        let normalizedTitle = SellItemValidation.normalizedTitle(title)
        let normalizedDetail = SellItemValidation.normalizedDetail(detail)
        try SellItemValidation.validateCreate(
            title: normalizedTitle,
            askingPrice: askingPrice,
            quantity: quantity,
            detail: normalizedDetail
        )

        let now = Date.now
        let item = SellItem(
            id: UUID(),
            title: normalizedTitle,
            askingPrice: askingPrice,
            quantity: quantity,
            detail: normalizedDetail,
            status: .active,
            createdAt: now,
            updatedAt: now
        )

        return try await repository.create(item)
    }
}
