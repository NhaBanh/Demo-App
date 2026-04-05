import Foundation

struct BuyCatalogListItem: Identifiable, Equatable, Hashable {
    let item: BuyItem
    let wishlistQuantity: Int

    var id: UUID { item.id }
    var isWishlisted: Bool { wishlistQuantity > 0 }
}
