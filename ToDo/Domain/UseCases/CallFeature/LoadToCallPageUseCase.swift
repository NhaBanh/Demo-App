import Foundation

struct LoadToCallPageUseCase {
    let repository: ToCallRepository

    func execute(page: Int, pageSize: Int, filter: String) async throws -> ToCallPage {
        try await repository.fetchPeople(page: page, pageSize: pageSize, filter: filter)
    }
}
