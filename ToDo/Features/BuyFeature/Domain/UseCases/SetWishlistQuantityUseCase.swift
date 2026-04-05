import Foundation

struct SetWishlistQuantityUseCase {
    let repository: WishlistRepository

    func execute(
        item: BuyItem,
        currentQuantity: Int,
        newQuantity: Int
    ) throws -> Int {
        try validateChange(
            item: item,
            currentQuantity: currentQuantity,
            newQuantity: newQuantity
        )

        return try repository.setQuantity(for: item, quantity: newQuantity)
    }

    private func validateChange(
        item: BuyItem,
        currentQuantity: Int,
        newQuantity: Int
    ) throws {
        guard newQuantity >= 0 else {
            throw AppError.validation("Wishlist quantity cannot be negative.")
        }

        guard newQuantity > currentQuantity else { return }

        guard item.availability == .available else {
            throw AppError.validation("Wishlist quantity can only be increased while the item is available.")
        }

        guard newQuantity <= item.availableQuantity else {
            throw AppError.validation("Wishlist quantity cannot exceed available stock (\(item.availableQuantity)).")
        }
    }
}
