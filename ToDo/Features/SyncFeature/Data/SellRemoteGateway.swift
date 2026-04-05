import Foundation

protocol SellRemoteGateway {
    func create(item: SellItem) async throws
    func update(item: SellItem) async throws
    func delete(itemID: UUID) async throws
}
