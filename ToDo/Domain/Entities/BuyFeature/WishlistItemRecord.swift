import Foundation

struct WishlistItemRecord: Equatable, Hashable {
    let item: BuyItem
    let quantity: Int
    let createdAt: Date
}
