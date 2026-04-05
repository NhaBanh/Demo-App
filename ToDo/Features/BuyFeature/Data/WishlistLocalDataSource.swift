import Foundation

@MainActor
protocol WishlistLocalDataSource {
    func wishlistRecords() throws -> [WishlistItemRecord]
    func setQuantity(for item: BuyItem, quantity: Int) throws -> Int
}
