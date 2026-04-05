import Combine
import Foundation

@MainActor
final class HomeSummaryViewModel: ObservableObject {
    @Published private(set) var summary = HomeSummary()

    private let buySummaryBuilder: BuySummaryBuilder
    private let sellSyncSummaryLoader: SellSyncSummaryLoader
    private var cancellables = Set<AnyCancellable>()

    init(
        sellRepository: SellRepository,
        syncRepository: SyncRepository,
        wishlistRepository: WishlistRepository,
        syncOrchestrator: SyncOrchestrator
    ) {
        buySummaryBuilder = BuySummaryBuilder(wishlistRepository: wishlistRepository)
        sellSyncSummaryLoader = SellSyncSummaryLoader(
            sellRepository: sellRepository,
            syncRepository: syncRepository
        )

        syncOrchestrator.completionPublisher
            .sink { [weak self] event in
                guard let self else { return }
                self.summary.sync.sessionSuccessCount += event.syncedCount
                Task { @MainActor [weak self] in
                    await self?.reloadSellAndSyncSummary()
                }
            }
            .store(in: &cancellables)
    }

    func loadInitialSummary() async {
        reloadInitialBuySummary()
        await reloadSellAndSyncSummary()
    }

    func reloadInitialBuySummary() {
        summary.buy = buySummaryBuilder.makeInitialSummary()
    }

    func reloadWishlistCount() {
        summary.buy.wishlistCount = buySummaryBuilder.makeWishlistCount()
    }

    func updateWishlistCount(_ wishlistCount: Int) {
        summary.buy.wishlistCount = wishlistCount
    }

    func setCallSummary(for people: [PersonToCall]) {
        summary.call = CallSummary(
            hotCount: people.filter { $0.priority == .hot }.count,
            warmCount: people.filter { $0.priority == .warm }.count,
            coldCount: people.filter { $0.priority == .cold }.count
        )
    }

    func updateBuy(items: [BuyCatalogListItem]) {
        summary.buy = buySummaryBuilder.makeSummary(items: items)
    }

    func reloadSellAndSyncSummary() async {
        guard let sellAndSyncSummary = try? await sellSyncSummaryLoader.load() else { return }
        summary.sell = sellAndSyncSummary.sell
        summary.sync.pendingCount = sellAndSyncSummary.sync.pendingCount
    }

    func updateSellCount(_ totalSellItems: Int) {
        summary.sell.totalSellItems = totalSellItems
    }

    func updatePendingSync(_ pendingCount: Int) {
        summary.sync.pendingCount = pendingCount
    }
}
