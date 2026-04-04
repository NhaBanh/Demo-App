import SwiftUI

struct ToBuyView: View {
    @StateObject private var viewModel: ToBuyViewModel
    @State private var selectedItem: ToBuyListItem?

    init(viewModel: ToBuyViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

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
                    ToBuyItemRow(
                        item: item,
                        onOpen: { selectedItem = item },
                        onIncrease: { Task { await viewModel.incrementQuantity(for: item) } },
                        onDecrease: { Task { await viewModel.decrementQuantity(for: item) } },
                    )
                }

                if viewModel.items.isEmpty, !viewModel.isLoading, viewModel.errorMessage == nil {
                    ContentUnavailableView(
                        "No Matching Items",
                        systemImage: "cart",
                        description: Text("Try a different search or sort to find what you need.")
                    )
                }
            }
        }
        .navigationTitle("To Buy")
        .searchable(text: $viewModel.filter, prompt: "Search items")
        .onSubmit(of: .search) {
            Task { await viewModel.applyFilter() }
        }
        .onChange(of: viewModel.filter) { _, _ in
            viewModel.scheduleFilterRefresh()
        }
        .onChange(of: viewModel.sort) { _, _ in
            Task { await viewModel.sortDidChange() }
        }
        .sheet(item: $selectedItem) { item in
            NavigationStack {
            ToBuyDetailView(
                item: item,
                onIncrease: { Task { await viewModel.incrementQuantity(for: item) } },
                onDecrease: { Task { await viewModel.decrementQuantity(for: item) } }
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
        .task {
            await viewModel.refresh()
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
}
