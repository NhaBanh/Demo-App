import Foundation

protocol WishlistRepository {
    func wishlistRecords() throws -> [WishlistItemRecord]
    func setQuantity(for item: BuyItem, quantity: Int) throws -> Int
}
