import Foundation

struct ToBuyListItem: Identifiable, Equatable, Hashable {
    let item: BuyItem
    let wishlistQuantity: Int

    var id: UUID { item.id }
}
