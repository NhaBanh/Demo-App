import Foundation

protocol CallRepository {
    func fetchPeople(page: Int, pageSize: Int, searchText: String?) async throws -> CallPage
    func totalCount() async throws -> Int
}

struct CallPage: Equatable {
    let items: [PersonToCall]
    let page: Int
    let totalPages: Int
    let lastSyncedAt: Date
}
