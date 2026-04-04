import Combine
import Foundation

@MainActor
final class SyncViewModel: ObservableObject {
    @Published private(set) var sellItems: [SellItem] = []
    @Published private(set) var pendingItems: [PendingSale] = []
    @Published private(set) var isLoading = false
    @Published var toastMessage: String?
    @Published var errorMessage: String?

    private let loadSellItems: LoadSellItemsUseCase
    private let loadPendingItems: LoadPendingSyncItemsUseCase
    private let markItemSold: MarkItemSoldUseCase
    private let syncPendingSellOperations: SyncPendingSellOperationsUseCase

    init(
        loadSellItems: LoadSellItemsUseCase,
        loadPendingItems: LoadPendingSyncItemsUseCase,
        markItemSold: MarkItemSoldUseCase,
        syncPendingSellOperations: SyncPendingSellOperationsUseCase
    ) {
        self.loadSellItems = loadSellItems
        self.loadPendingItems = loadPendingItems
        self.markItemSold = markItemSold
        self.syncPendingSellOperations = syncPendingSellOperations
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let pending = loadPendingItems.execute()
            let page = try await loadSellItems.execute(
                query: SellItemsQuery(status: .available, page: 1, pageSize: 100)
            )
            sellItems = page.items
            pendingItems = try await pending
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markSold(itemID: UUID) async {
        do {
            try await markItemSold.execute(itemID: itemID)
            toastMessage = "Sell change queued for sync."
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func syncNow() async {
        do {
            let count = try await syncPendingSellOperations.execute()
            toastMessage = "Synced \(count) sell change(s)."
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
