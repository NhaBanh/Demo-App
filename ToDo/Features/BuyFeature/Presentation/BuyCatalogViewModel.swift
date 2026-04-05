import Combine
import Foundation

@MainActor
final class BuyCatalogViewModel: ObservableObject {
    struct ViewState: Equatable {
        var items: [BuyCatalogListItem] = []
        var page = 1
        var hasMore = false
        var totalCount = 0
    }

    @Published private(set) var viewState = ViewState()
    @Published var sort: BuySortOption = .title
    @Published var availabilityFilter: BuyAvailabilityFilter = .all
    @Published var categoryFilter: BuyCategoryFilter = .all
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingNextPage = false
    @Published var errorMessage: String?

    private let loader: BuyCatalogLoader
    private let setWishlistQuantity: SetWishlistQuantityUseCase
    private var hasLoadedOnce = false
    private var lastRefreshAt: Date?

    init(
        loadItems: LoadBuyCatalogUseCase,
        setWishlistQuantity: SetWishlistQuantityUseCase
    ) {
        loader = BuyCatalogLoader(loadItems: loadItems)
        self.setWishlistQuantity = setWishlistQuantity
    }

    func refresh() async {
        await startRefresh(showsLoadingOverlay: items.isEmpty)
    }

    func loadOnAppear() async {
        guard shouldRefreshOnAppear else { return }

        await startRefresh(showsLoadingOverlay: items.isEmpty)
    }

    func loadNextPageIfNeeded(currentItem item: BuyCatalogListItem) async {
        guard hasMore, !isLoading, !isLoadingNextPage, item.id == items.last?.id else { return }

        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        do {
            let page = try await loader.loadNextPage(
                query: makeQuerySnapshot(),
                nextPage: viewState.page + 1
            )
            append(page)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sortDidChange() async {
        await startRefresh(showsLoadingOverlay: items.isEmpty)
    }

    func filtersDidChange() async {
        await startRefresh(showsLoadingOverlay: items.isEmpty)
    }

    func retry() async {
        await startRefresh(showsLoadingOverlay: true)
    }

    func saveToWishlist(_ item: BuyCatalogListItem) async {
        guard item.wishlistQuantity == 0 else { return }

        do {
            let updatedQuantity = try setWishlistQuantity.execute(
                item: item.item,
                currentQuantity: item.wishlistQuantity,
                newQuantity: 1
            )
            viewState.items = viewState.items.map { existingItem in
                guard existingItem.id == item.id else { return existingItem }
                return BuyCatalogListItem(
                    item: existingItem.item,
                    wishlistQuantity: updatedQuantity
                )
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var items: [BuyCatalogListItem] {
        viewState.items
    }

    var hasMore: Bool {
        viewState.hasMore
    }

    var totalCount: Int {
        viewState.totalCount
    }

    var emptyStateTitle: String {
        return "No Matching Items"
    }

    var emptyStateDescription: String {
        return "Try a different sort or check back later."
    }

    private var shouldRefreshOnAppear: Bool {
        loader.shouldRefreshOnAppear(hasLoadedOnce: hasLoadedOnce, lastRefreshAt: lastRefreshAt)
    }

    private func startRefresh(showsLoadingOverlay: Bool) async {
        if showsLoadingOverlay {
            isLoading = true
        }
        await loader.refresh(
            query: makeQuerySnapshot(),
            perform: { [loader] in
                try await loader.loadFirstPage(query: self.makeQuerySnapshot())
            },
            apply: { [weak self] page in
                self?.replace(with: page)
            },
            finish: { [weak self] in
                guard let self else { return }
                self.hasLoadedOnce = true
                self.lastRefreshAt = Date()
                self.errorMessage = nil
                self.isLoading = false
            },
            onError: { [weak self] message in
                self?.errorMessage = message
                self?.isLoading = false
            }
        )
    }

    private func replace(with page: BuyCatalogPage) {
        viewState = ViewState(
            items: page.items,
            page: page.page,
            hasMore: page.hasMore,
            totalCount: page.totalCount
        )
    }

    private func append(_ page: BuyCatalogPage) {
        viewState.items.append(contentsOf: page.items)
        viewState.page = page.page
        viewState.hasMore = page.hasMore
        viewState.totalCount = page.totalCount
    }

    private func makeQuerySnapshot() -> BuyCatalogLoader.QuerySnapshot {
        BuyCatalogLoader.QuerySnapshot(
            sort: sort,
            availability: availabilityFilter.itemAvailability,
            category: categoryFilter.category
        )
    }
}
