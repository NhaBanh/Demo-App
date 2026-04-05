import SwiftUI

struct RootView: View {
    let container: AppContainer
    @StateObject private var homeSummaryViewModel: HomeSummaryViewModel
    @StateObject private var callViewModel: CallViewModel
    @StateObject private var buyCatalogViewModel: BuyCatalogViewModel
    @StateObject private var wishlistViewModel: WishlistViewModel
    @StateObject private var toSellViewModel: ToSellViewModel
    @StateObject private var syncViewModel: SyncViewModel
    @State private var selectedModule: AppModule?
    @State private var isShowingWishlist = false

    init(container: AppContainer) {
        self.container = container
        _homeSummaryViewModel = StateObject(wrappedValue: container.makeHomeSummaryViewModel())
        _callViewModel = StateObject(wrappedValue: container.makeToCallViewModel())
        _buyCatalogViewModel = StateObject(wrappedValue: container.makeBuyCatalogViewModel())
        _wishlistViewModel = StateObject(wrappedValue: container.makeWishlistViewModel())
        _toSellViewModel = StateObject(wrappedValue: container.makeToSellViewModel())
        _syncViewModel = StateObject(wrappedValue: container.makeSyncViewModel())
    }

    var body: some View {
        Group {
            if let selectedModule {
                moduleContainer(for: selectedModule)
            } else {
                NavigationStack {
                    HomeView(summary: homeSummaryViewModel.summary) { module in
                        selectedModule = module
                    }
                }
            }
        }
        .onReceive(callViewModel.$people) { people in
            homeSummaryViewModel.setCallSummary(for: people)
        }
        .onReceive(buyCatalogViewModel.$viewState) { state in
            homeSummaryViewModel.updateBuy(items: state.items)
        }
        .onReceive(wishlistViewModel.$items) { items in
            homeSummaryViewModel.updateWishlistCount(items.count)
        }
        .onReceive(toSellViewModel.$totalCount) { totalCount in
            homeSummaryViewModel.updateSellCount(totalCount)
        }
        .onReceive(syncViewModel.$queuedOperations) { operations in
            homeSummaryViewModel.updatePendingSync(operations.count)
        }
        .task {
            await homeSummaryViewModel.loadInitialSummary()
        }
    }

    @ViewBuilder
    private func moduleContainer(for module: AppModule) -> some View {
        NavigationStack {
            moduleView(for: module)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Home") {
                            selectedModule = nil
                        }
                    }

                    if module == .toBuy {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Wishlist") {
                                isShowingWishlist = true
                            }
                        }
                    }
                }
        }
        .sheet(isPresented: $isShowingWishlist) {
            NavigationStack {
                WishlistView(viewModel: wishlistViewModel)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") {
                                isShowingWishlist = false
                            }
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func moduleView(for module: AppModule) -> some View {
        switch module {
        case .toCall:
            CallView(viewModel: callViewModel)
        case .toBuy:
            BuyCatalogView(viewModel: buyCatalogViewModel)
        case .toSell:
            ToSellView(viewModel: toSellViewModel)
        case .sync:
            SyncView(viewModel: syncViewModel)
        }
    }
}
