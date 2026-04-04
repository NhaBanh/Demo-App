import Foundation

struct UpdateWishlistQuantityUseCase {
    let repository: WishlistRepository

    func execute(item: ToBuyListItem, quantity: Int) throws -> Int {
        try repository.setQuantity(for: item.item, quantity: quantity)
    }
}
