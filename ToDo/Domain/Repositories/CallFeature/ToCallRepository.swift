import Foundation

protocol ToCallRepository {
    func fetchPeople(page: Int, pageSize: Int, filter: String) async throws -> ToCallPage
    func totalCount() async throws -> Int
}

struct ToCallPage: Equatable {
    let items: [PersonToCall]
    let page: Int
    let totalPages: Int
    let lastSyncedAt: Date
}
