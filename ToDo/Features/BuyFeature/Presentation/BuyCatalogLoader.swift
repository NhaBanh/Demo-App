import Foundation

@MainActor
final class BuyCatalogLoader {
    struct QuerySnapshot {
        let sort: BuySortOption
        let availability: BuyItemAvailability?
        let category: BuyCategory?
    }

    private let loadItems: LoadBuyCatalogUseCase
    private let pageSize: Int
    private let silentRefreshInterval: TimeInterval
    private var refreshTask: Task<Void, Never>?
    private var requestGeneration = 0

    init(
        loadItems: LoadBuyCatalogUseCase,
        pageSize: Int = 20,
        silentRefreshInterval: TimeInterval = 60
    ) {
        self.loadItems = loadItems
        self.pageSize = pageSize
        self.silentRefreshInterval = silentRefreshInterval
    }

    func shouldRefreshOnAppear(hasLoadedOnce: Bool, lastRefreshAt: Date?) -> Bool {
        guard hasLoadedOnce else { return true }
        guard let lastRefreshAt else { return true }
        return Date().timeIntervalSince(lastRefreshAt) >= silentRefreshInterval
    }

    func refresh(
        query: QuerySnapshot,
        perform: @escaping @MainActor () async throws -> BuyCatalogPage,
        apply: @escaping @MainActor (BuyCatalogPage) -> Void,
        finish: @escaping @MainActor () -> Void,
        onError: @escaping @MainActor (String) -> Void
    ) async {
        refreshTask?.cancel()
        requestGeneration += 1
        let generation = requestGeneration

        refreshTask = Task { @MainActor in
            do {
                let page = try await perform()
                guard !Task.isCancelled, generation == requestGeneration else { return }
                apply(page)
                finish()
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, generation == requestGeneration else { return }
                onError(error.localizedDescription)
            }
        }

        await refreshTask?.value
    }

    func loadFirstPage(query: QuerySnapshot) async throws -> BuyCatalogPage {
        try await loadItems.execute(
            sort: query.sort,
            availability: query.availability,
            category: query.category,
            page: 1,
            pageSize: pageSize
        )
    }

    func loadNextPage(query: QuerySnapshot, nextPage: Int) async throws -> BuyCatalogPage {
        try await loadItems.execute(
            sort: query.sort,
            availability: query.availability,
            category: query.category,
            page: nextPage,
            pageSize: pageSize
        )
    }
}
