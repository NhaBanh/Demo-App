import Combine
import Foundation

@MainActor
final class ToSellViewModel: ObservableObject {
    @Published private(set) var items: [SellItem] = []
    @Published private(set) var lastDeletedItems: [SellItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingNextPage = false
    @Published private(set) var hasMore = false
    @Published private(set) var totalCount = 0
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var statusFilter: SellItemStatusFilter = .all

    private let loadItems: LoadSellItemsUseCase
    private let createItem: CreateSellItemUseCase
    private let updateItem: UpdateSellItemUseCase
    private let deleteItems: DeleteSellItemsUseCase
    private let restoreItems: RestoreSellItemsUseCase
    private let pageSize = 20
    private var currentPage = 1
    private var refreshTask: Task<Void, Never>?

    init(
        loadItems: LoadSellItemsUseCase,
        createItem: CreateSellItemUseCase,
        updateItem: UpdateSellItemUseCase,
        deleteItems: DeleteSellItemsUseCase,
        restoreItems: RestoreSellItemsUseCase
    ) {
        self.loadItems = loadItems
        self.createItem = createItem
        self.updateItem = updateItem
        self.deleteItems = deleteItems
        self.restoreItems = restoreItems
    }

    func refresh() async {
        currentPage = 1
        isLoading = true
        defer { isLoading = false }

        do {
            let page = try await loadItems.execute(query: makeQuery(page: currentPage))
            items = page.items
            hasMore = page.hasMore
            totalCount = page.totalCount
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadNextPageIfNeeded(currentItem item: SellItem) async {
        guard hasMore, !isLoading, !isLoadingNextPage, item.id == items.last?.id else { return }

        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        do {
            let nextPage = currentPage + 1
            let page = try await loadItems.execute(query: makeQuery(page: nextPage))
            items.append(contentsOf: page.items)
            currentPage = page.page
            hasMore = page.hasMore
            totalCount = page.totalCount
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func scheduleRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            await self?.refresh()
        }
    }

    func add(name: String, price: Decimal, quantity: Int, notes: String) async -> Bool {
        do {
            _ = try await createItem.execute(name: name, askingPrice: price, quantity: quantity, notes: notes)
            await refresh()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func save(_ item: SellItem) async {
        do {
            _ = try await updateItem.execute(item)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(ids: [UUID]) async {
        do {
            lastDeletedItems = try await deleteItems.execute(ids: ids)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func undoDelete() async {
        guard !lastDeletedItems.isEmpty else { return }
        do {
            try await restoreItems.execute(items: lastDeletedItems)
            lastDeletedItems = []
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func makeQuery(page: Int) -> SellItemsQuery {
        SellItemsQuery(
            searchText: searchText,
            status: statusFilter,
            sort: .updatedAtDescending,
            page: page,
            pageSize: pageSize
        )
    }
}
