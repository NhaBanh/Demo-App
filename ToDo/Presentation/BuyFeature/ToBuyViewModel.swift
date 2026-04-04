import Combine
import Foundation

@MainActor
final class ToBuyViewModel: ObservableObject {
    @Published private(set) var items: [ToBuyListItem] = []
    @Published var filter = ""
    @Published var sort: BuySortOption = .title
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let loadItems: LoadToBuyCatalogUseCase
    private let updateWishlistQuantity: UpdateWishlistQuantityUseCase
    private var refreshTask: Task<Void, Never>?

    init(
        loadItems: LoadToBuyCatalogUseCase,
        updateWishlistQuantity: UpdateWishlistQuantityUseCase
    ) {
        self.loadItems = loadItems
        self.updateWishlistQuantity = updateWishlistQuantity
    }

    func refresh() async {
        refreshTask?.cancel()
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await loadItems.execute(filter: filter, sort: sort)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applyFilter() async {
        await refresh()
    }

    func sortDidChange() async {
        await refresh()
    }

    func scheduleFilterRefresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await self?.refresh()
        }
    }

    func retry() async {
        await refresh()
    }

    func incrementQuantity(for item: ToBuyListItem) async {
        await setQuantity(for: item, quantity: item.wishlistQuantity + 1)
    }

    func decrementQuantity(for item: ToBuyListItem) async {
        await setQuantity(for: item, quantity: max(0, item.wishlistQuantity - 1))
    }

    func setQuantity(for item: ToBuyListItem, quantity: Int) async {
        do {
            let updatedQuantity = try updateWishlistQuantity.execute(item: item, quantity: quantity)
            items = items.map { existingItem in
                guard existingItem.id == item.id else { return existingItem }
                return ToBuyListItem(item: existingItem.item, wishlistQuantity: updatedQuantity)
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
