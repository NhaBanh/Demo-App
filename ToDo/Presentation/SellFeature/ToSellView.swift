import SwiftUI

struct ToSellView: View {
    @StateObject private var viewModel: ToSellViewModel
    @State private var draft = SellItemDraft()
    @State private var selectedIDs = Set<UUID>()

    init(viewModel: ToSellViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List(selection: $selectedIDs) {
            Section("Add Item") {
                TextField("Name", text: $draft.name)
                TextField("Price", value: $draft.price, format: .number)
                Stepper("Quantity: \(draft.quantity)", value: $draft.quantity, in: 1...100)
                TextField("Notes", text: $draft.notes, axis: .vertical)
                Button("Create Item") {
                    Task {
                        let didCreate = await viewModel.add(
                            name: draft.name,
                            price: draft.price,
                            quantity: draft.quantity,
                            notes: draft.notes
                        )
                        if didCreate {
                            draft = SellItemDraft()
                        }
                    }
                }
            }

            Section("Filters") {
                Picker("Status", selection: $viewModel.statusFilter) {
                    Text("All").tag(SellItemStatusFilter.all)
                    Text("Available").tag(SellItemStatusFilter.available)
                    Text("Sold").tag(SellItemStatusFilter.sold)
                }
                .pickerStyle(.segmented)

                Text("\(viewModel.totalCount) item(s)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section("Inventory") {
                ForEach(viewModel.items) { item in
                    SellItemRow(item: item) { updated in
                        Task { await viewModel.save(updated) }
                    }
                    .onAppear {
                        Task { await viewModel.loadNextPageIfNeeded(currentItem: item) }
                    }
                }

                if viewModel.items.isEmpty, !viewModel.isLoading, viewModel.errorMessage == nil {
                    ContentUnavailableView(
                        "No Sell Items",
                        systemImage: "tag",
                        description: Text("Try a different search or filter, or create a new item.")
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
        .navigationTitle("To Sell")
        .searchable(text: $viewModel.searchText, prompt: "Search inventory")
        .onSubmit(of: .search) {
            Task { await viewModel.refresh() }
        }
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.scheduleRefresh()
        }
        .onChange(of: viewModel.statusFilter) { _, _ in
            Task { await viewModel.refresh() }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if !selectedIDs.isEmpty {
                    Button("Bulk Delete") {
                        Task {
                            await viewModel.delete(ids: Array(selectedIDs))
                            selectedIDs.removeAll()
                        }
                    }
                }
            }

            ToolbarItem(placement: .automatic) {
                if !viewModel.lastDeletedItems.isEmpty {
                    Button("Undo Delete") {
                        Task { await viewModel.undoDelete() }
                    }
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading inventory...")
            }
        }
        .task {
            await viewModel.refresh()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

private struct SellItemDraft {
    var name = ""
    var price: Decimal = 10
    var quantity = 1
    var notes = ""
}

private struct SellItemRow: View {
    @State private var draft: SellItem
    let onSave: (SellItem) -> Void

    init(item: SellItem, onSave: @escaping (SellItem) -> Void) {
        _draft = State(initialValue: item)
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(draft.isSold ? "Sold" : "Available")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(draft.isSold ? .green : .secondary)
                Spacer()
                Text("Updated \(draft.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextField("Name", text: Binding(
                get: { draft.name },
                set: { draft = draft.with(name: $0) }
            ))
            TextField("Price", value: Binding(
                get: { draft.askingPrice },
                set: { draft = draft.with(price: $0) }
            ), format: .number)
            Stepper("Quantity: \(draft.quantity)", value: Binding(
                get: { draft.quantity },
                set: { draft = draft.with(quantity: $0) }
            ), in: 1...100)
            TextField("Notes", text: Binding(
                get: { draft.notes },
                set: { draft = draft.with(notes: $0) }
            ))
            Button("Save Changes") {
                onSave(draft)
            }
        }
        .padding(.vertical, 4)
    }
}

private extension SellItem {
    func with(name: String? = nil, price: Decimal? = nil, quantity: Int? = nil, notes: String? = nil) -> SellItem {
        SellItem(
            id: id,
            name: name ?? self.name,
            askingPrice: price ?? askingPrice,
            quantity: quantity ?? self.quantity,
            notes: notes ?? self.notes,
            isSold: isSold,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
