import SwiftUI

struct WishlistView: View {
    @ObservedObject var viewModel: WishlistViewModel

    var body: some View {
        List {
            Section("Filter") {
                Picker("Status", selection: $viewModel.filter) {
                    ForEach(WishlistDisplayFilter.allCases) { filter in
                        Text(filterLabel(filter)).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    ContentUnavailableView(
                        "Unable to Load Wishlist",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )

                    Button("Retry") {
                        Task { await viewModel.refresh() }
                    }
                }
            }

            Section("Saved Items") {
                ForEach(viewModel.filteredItems, id: \.item.id) { item in
                    WishlistItemRow(
                        record: item,
                        onIncrease: { Task { await viewModel.incrementQuantity(for: item) } },
                        onDecrease: { Task { await viewModel.decrementQuantity(for: item) } }
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task { await viewModel.remove(item) }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }

                if viewModel.filteredItems.isEmpty, !viewModel.isLoading, viewModel.errorMessage == nil {
                    ContentUnavailableView(
                        viewModel.emptyStateTitle,
                        systemImage: "heart",
                        description: Text(viewModel.emptyStateDescription)
                    )
                }
            }
        }
        .navigationTitle("Wishlist")
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading wishlist...")
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

    private func filterLabel(_ filter: WishlistDisplayFilter) -> String {
        switch filter {
        case .all:
            "All"
        case .available:
            "Available"
        case .attentionNeeded:
            "Attention"
        }
    }
}
