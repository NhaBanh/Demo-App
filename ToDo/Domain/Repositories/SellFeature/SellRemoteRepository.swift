import Foundation

protocol SellRemoteRepository {
    func create(item: SellItem) async throws
    func update(item: SellItem) async throws
    func delete(itemID: UUID) async throws
    func markSold(itemID: UUID) async throws
    func fetchItems() async throws -> [SellItem]
}
