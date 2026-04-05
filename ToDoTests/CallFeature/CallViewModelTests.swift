import XCTest
@testable import ToDo

@MainActor
final class CallViewModelTests: XCTestCase {
    func testRefreshLoadsCurrentPage() async {
        let person = PersonToCall.fixture()
        let repository = CallRepositoryFake()
        repository.fetchPeopleResult = .success(
            CallPage(items: [person], page: 1, totalPages: 4, lastSyncedAt: .now)
        )
        let viewModel = CallViewModel(
            repository: repository,
            connectivityMonitor: ConnectivityMonitorFake(isConnected: true)
        )

        await viewModel.refresh()
        await Task.yield()

        XCTAssertEqual(viewModel.people, [person])
        XCTAssertEqual(viewModel.page, 1)
        XCTAssertEqual(viewModel.totalPages, 4)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testNextPageRequestsFollowingPage() async {
        let repository = CallRepositoryFake()
        repository.fetchPeopleHandler = { page, _, _ in
            CallPage(items: [.fixture(name: "Page \(page)")], page: page, totalPages: 3, lastSyncedAt: .now)
        }
        let viewModel = CallViewModel(
            repository: repository,
            connectivityMonitor: ConnectivityMonitorFake(isConnected: true)
        )

        await viewModel.refresh()
        await Task.yield()
        await viewModel.nextPage()
        await Task.yield()

        XCTAssertEqual(repository.receivedPageRequests.map(\.page), [1, 2])
        XCTAssertEqual(viewModel.page, 2)
        XCTAssertEqual(viewModel.people.first?.name, "Page 2")
    }

    func testSearchTextResetsToFirstPageAndRequestsFilteredPeople() async {
        let repository = CallRepositoryFake()
        repository.fetchPeopleHandler = { page, _, searchText in
            CallPage(
                items: [.fixture(name: "\(searchText ?? "all") page \(page)")],
                page: page,
                totalPages: 2,
                lastSyncedAt: .now
            )
        }
        let viewModel = CallViewModel(
            repository: repository,
            connectivityMonitor: ConnectivityMonitorFake(isConnected: true)
        )

        await viewModel.refresh()
        await Task.yield()
        await viewModel.nextPage()
        await Task.yield()
        viewModel.searchText = "ava"
        await viewModel.searchTextDidChange()
        await Task.yield()

        XCTAssertEqual(
            repository.receivedPageRequests,
            [
                .init(page: 1, pageSize: 3, searchText: nil),
                .init(page: 2, pageSize: 3, searchText: nil),
                .init(page: 1, pageSize: 3, searchText: "ava")
            ]
        )
        XCTAssertEqual(viewModel.page, 1)
        XCTAssertEqual(viewModel.people.first?.name, "ava page 1")
    }

    func testTransientFailurePublishesRetryMessage() async {
        let repository = CallRepositoryFake()
        repository.fetchPeopleResult = .failure(AppError.transientNetwork("Temporary network issue while loading contacts."))
        let viewModel = CallViewModel(
            repository: repository,
            connectivityMonitor: ConnectivityMonitorFake(isConnected: true)
        )

        await viewModel.refresh()
        try? await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(viewModel.errorMessage, "Temporary network issue while loading contacts.")
        XCTAssertEqual(viewModel.retryStatusMessage, "Temporary network issue. Retrying in 3s...")
    }
}
