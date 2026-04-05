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
    @Published var statusFilter: SellItemStatusFilter = .all

    private let inventoryReader: SellInventoryReader
    private let inventoryWriter: SellInventoryWriter
    private let createItem: CreateSellItemUseCase
    private let updateItem: UpdateSellItemUseCase
    private let sellAmount: SellAmountUseCase
    private let pageSize = 20
    private var currentPage = 1

    init(
        inventoryReader: SellInventoryReader,
        inventoryWriter: SellInventoryWriter,
        createItem: CreateSellItemUseCase,
        updateItem: UpdateSellItemUseCase,
        sellAmount: SellAmountUseCase
    ) {
        self.inventoryReader = inventoryReader
        self.inventoryWriter = inventoryWriter
        self.createItem = createItem
        self.updateItem = updateItem
        self.sellAmount = sellAmount
    }

    func refresh() async {
        currentPage = 1
        isLoading = true
        defer { isLoading = false }

        do {
            let page = try await inventoryReader.fetchItems(query: makeQuery(page: currentPage))
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
            let page = try await inventoryReader.fetchItems(query: makeQuery(page: nextPage))
            items.append(contentsOf: page.items)
            currentPage = page.page
            hasMore = page.hasMore
            totalCount = page.totalCount
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func add(title: String, price: Decimal, quantity: Int, detail: String) async -> Bool {
        await performMutationReturningResult {
            _ = try await createItem.execute(title: title, askingPrice: price, quantity: quantity, detail: detail)
        }
    }

    func save(_ item: SellItem) async {
        await performMutation {
            _ = try await updateItem.execute(item)
        }
    }

    func sell(item: SellItem, amount: Int) async {
        await performMutation {
            _ = try await sellAmount.execute(itemID: item.id, amount: amount)
        }
    }

    func delete(ids: [UUID]) async {
        await performMutation {
            lastDeletedItems = try await inventoryWriter.delete(ids: ids)
        }
    }

    func undoDelete() async {
        guard !lastDeletedItems.isEmpty else { return }
        await performMutation {
            try await inventoryWriter.restore(items: lastDeletedItems)
            lastDeletedItems = []
        }
    }

    func clearUndoState() {
        lastDeletedItems = []
    }

    private func makeQuery(page: Int) -> SellItemsQuery {
        SellItemsQuery(
            status: statusFilter,
            sort: .updatedAtDescending,
            page: page,
            pageSize: pageSize
        )
    }

    private func performMutation(
        _ operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            await refresh()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func performMutationReturningResult(
        _ operation: () async throws -> Void
    ) async -> Bool {
        do {
            try await operation()
            await refresh()
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
