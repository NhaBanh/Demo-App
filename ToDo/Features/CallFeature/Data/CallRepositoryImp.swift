import Foundation

struct CallRepositoryImp: CallRepository {
    let server: MockToCallServer

    func fetchPeople(page: Int, pageSize: Int, searchText: String?) async throws -> CallPage {
        let response = try await server.fetchPeople(page: page, pageSize: pageSize, searchText: searchText)
        return CallPage(
            items: response.items.map { $0.toDomain() },
            page: response.page,
            totalPages: response.totalPages,
            lastSyncedAt: response.lastSyncedAt
        )
    }

    func totalCount() async throws -> Int {
        await server.totalCount()
    }
}
