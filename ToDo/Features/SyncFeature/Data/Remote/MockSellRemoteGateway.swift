import Foundation

struct MockSellRemoteGateway: SellRemoteGateway {
    let server: MockInventoryServer

    func create(item: SellItem) async throws {
        try await server.createSellItem(RemoteSellItemDTO(item: item))
    }

    func update(item: SellItem) async throws {
        try await server.updateSellItem(RemoteSellItemDTO(item: item))
    }

    func delete(itemID: UUID) async throws {
        try await server.deleteSellItem(id: itemID)
    }
}
