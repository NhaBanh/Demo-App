import Foundation

struct RemoteSellRepositoryImp: SellRemoteRepository {
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

    func markSold(itemID: UUID) async throws {
        try await server.markSellItemSold(id: itemID)
    }

    func fetchItems() async throws -> [SellItem] {
        try await server.fetchSellItems().map { $0.toDomain() }
    }
}
