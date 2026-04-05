import Combine
import Foundation

enum WishlistDisplayFilter: String, CaseIterable, Identifiable {
    case all
    case available
    case attentionNeeded

    var id: String { rawValue }
}

@MainActor
final class WishlistViewModel: ObservableObject {
    @Published private(set) var items: [WishlistItemRecord] = []
    @Published var filter: WishlistDisplayFilter = .all
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let loadItems: LoadWishlistUseCase
    private let setQuantity: SetWishlistQuantityUseCase
    private var refreshGeneration = 0

    init(
        loadItems: LoadWishlistUseCase,
        setQuantity: SetWishlistQuantityUseCase
    ) {
        self.loadItems = loadItems
        self.setQuantity = setQuantity
    }

    func loadOnAppear() async {
        if items.isEmpty {
            await refresh()
        }
    }

    func refresh() async {
        refreshGeneration += 1
        let generation = refreshGeneration
        isLoading = true

        do {
            let result = try await loadItems.execute()
            guard generation == refreshGeneration else { return }

            items = result.initialItems
            errorMessage = nil
            isLoading = false

            if let refreshedItemsTask = result.refreshedItemsTask,
               let refreshedItems = await refreshedItemsTask.value,
               generation == refreshGeneration {
                items = refreshedItems
            }
        } catch {
            guard generation == refreshGeneration else { return }
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func incrementQuantity(for item: WishlistItemRecord) async {
        await setQuantity(for: item, quantity: item.quantity + 1)
    }

    func decrementQuantity(for item: WishlistItemRecord) async {
        await setQuantity(for: item, quantity: max(0, item.quantity - 1))
    }

    func setQuantity(for item: WishlistItemRecord, quantity: Int) async {
        do {
            let updatedQuantity = try setQuantity.execute(
                item: item.item,
                currentQuantity: item.quantity,
                newQuantity: quantity
            )
            if updatedQuantity == 0 {
                items.removeAll { $0.item.id == item.item.id }
            } else {
                items = items.map { existing in
                    guard existing.item.id == item.item.id else { return existing }
                    return WishlistItemRecord(
                        item: existing.item,
                        quantity: updatedQuantity,
                        createdAt: existing.createdAt
                    )
                }
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func remove(_ item: WishlistItemRecord) async {
        await setQuantity(for: item, quantity: 0)
    }

    var filteredItems: [WishlistItemRecord] {
        switch filter {
        case .all:
            items
        case .available:
            items.filter { $0.item.availability == .available }
        case .attentionNeeded:
            items.filter { $0.item.availability != .available }
        }
    }

    var availableCount: Int {
        items.filter { $0.item.availability == .available }.count
    }

    var outOfStockCount: Int {
        items.filter { $0.item.availability == .outOfStock }.count
    }

    var removedCount: Int {
        items.filter { $0.item.availability == .removedFromCatalog }.count
    }

    var emptyStateTitle: String {
        switch filter {
        case .all:
            "Wishlist Is Empty"
        case .available:
            "No Available Wishlist Items"
        case .attentionNeeded:
            "No Items Need Attention"
        }
    }

    var emptyStateDescription: String {
        switch filter {
        case .all:
            "Saved items will appear here after you add them from the To Buy catalog."
        case .available:
            "Available wishlist items will show up here when the saved server snapshot says they can still be bought."
        case .attentionNeeded:
            "Out-of-stock and removed wishlist items will show up here when they need a review."
        }
    }
}
