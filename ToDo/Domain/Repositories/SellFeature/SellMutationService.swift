import Foundation

protocol SellMutationService {
    func create(name: String, askingPrice: Decimal, quantity: Int, notes: String) async throws -> SellItem
    func update(_ item: SellItem) async throws -> SellItem
    func delete(ids: [UUID]) async throws -> [SellItem]
    func markSold(itemID: UUID) async throws
}
