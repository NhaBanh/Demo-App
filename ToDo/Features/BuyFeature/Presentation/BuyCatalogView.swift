import SwiftUI

struct BuyCatalogView: View {
    @ObservedObject var viewModel: BuyCatalogViewModel
    @State private var selectedItem: BuyCatalogListItem?

    var body: some View {
        List {
            Section("Sort") {
                Picker("Sort", selection: $viewModel.sort) {
                    ForEach(BuySortOption.allCases) { option in
                        Text(optionLabel(option)).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Filter") {
                Picker("Availability", selection: $viewModel.availabilityFilter) {
                    ForEach(BuyAvailabilityFilter.allCases) { option in
                        Text(availabilityLabel(option)).tag(option)
                    }
                }

                Picker("Category", selection: $viewModel.categoryFilter) {
                    ForEach(BuyCategoryFilter.allCases) { option in
                        Text(categoryLabel(option)).tag(option)
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    ContentUnavailableView(
                        "Unable to Load Items",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )

                    Button("Retry") {
                        Task { await viewModel.retry() }
                    }
                }
            }

            Section("Items") {
                ForEach(viewModel.items) { item in
                    BuyCatalogItemRow(
                        item: item,
                        onOpen: { selectedItem = item },
                        onSave: { Task { await viewModel.saveToWishlist(item) } }
                    )
                    .onAppear {
                        Task { await viewModel.loadNextPageIfNeeded(currentItem: item) }
                    }
                }

                if viewModel.items.isEmpty, !viewModel.isLoading, viewModel.errorMessage == nil {
                    ContentUnavailableView(
                        viewModel.emptyStateTitle,
                        systemImage: "cart",
                        description: Text(viewModel.emptyStateDescription)
                    )
                }

                if viewModel.isLoadingNextPage {
                    HStack {
                        Spacer()
                        ProgressView("Loading more...")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("To Buy")
        .onChange(of: viewModel.sort) { _, _ in
            Task { await viewModel.sortDidChange() }
        }
        .onChange(of: viewModel.availabilityFilter) { _, _ in
            Task { await viewModel.filtersDidChange() }
        }
        .onChange(of: viewModel.categoryFilter) { _, _ in
            Task { await viewModel.filtersDidChange() }
        }
        .sheet(item: $selectedItem) { item in
            NavigationStack {
            BuyCatalogDetailView(
                item: item,
                onSave: { Task { await viewModel.saveToWishlist(item) } }
            )
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading items...")
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .onAppear {
            Task { await viewModel.loadOnAppear() }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private func optionLabel(_ option: BuySortOption) -> String {
        switch option {
        case .title:
            "Title"
        case .priceLowToHigh:
            "Price: Low to High"
        case .priceHighToLow:
            "Price: High to Low"
        }
    }

    private func availabilityLabel(_ option: BuyAvailabilityFilter) -> String {
        switch option {
        case .all:
            "All"
        case .available:
            "Available"
        case .outOfStock:
            "Out of stock"
        case .removedFromCatalog:
            "Removed"
        }
    }

    private func categoryLabel(_ option: BuyCategoryFilter) -> String {
        switch option {
        case .all:
            "All"
        case .office:
            "Office"
        case .hardware:
            "Hardware"
        case .household:
            "Household"
        }
    }
}
