import SwiftUI

struct ToSellView: View {
    @ObservedObject var viewModel: ToSellViewModel
    @State private var draft = SellItemDraft()
    @State private var selectedIDs = Set<UUID>()
    @State private var isSelecting = false
    @State private var isShowingBulkDeleteConfirmation = false

    var body: some View {
        List {
            Section("Add Item") {
                TextField("Title", text: $draft.title)
                TextField("Price", value: $draft.price, format: .number)
                Stepper("Quantity: \(draft.quantity)", value: $draft.quantity, in: 1...100)
                TextField("Detail", text: $draft.detail, axis: .vertical)
                Button("Create Item") {
                    Task {
                        let didCreate = await viewModel.add(
                            title: draft.title,
                            price: draft.price,
                            quantity: draft.quantity,
                            detail: draft.detail
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
                    Text("Sold Out").tag(SellItemStatusFilter.soldOut)
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
                    SellItemRow(
                        item: item,
                        isSelecting: isSelecting,
                        isSelected: selectedIDs.contains(item.id),
                        onToggleSelection: { toggleSelection(for: item.id) }
                    ) { updated in
                        Task { await viewModel.save(updated) }
                    } onSell: { soldItem, amount in
                        Task { await viewModel.sell(item: soldItem, amount: amount) }
                    }
                    .onAppear {
                        Task { await viewModel.loadNextPageIfNeeded(currentItem: item) }
                    }
                }

                if viewModel.items.isEmpty, !viewModel.isLoading, viewModel.errorMessage == nil {
                    ContentUnavailableView(
                        "No Sell Items",
                        systemImage: "tag",
                        description: Text("Try a different status filter, or create a new item.")
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
        .onChange(of: viewModel.statusFilter) { _, _ in
            Task { await viewModel.refresh() }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(isSelecting ? "Done" : "Select") {
                    isSelecting.toggle()
                    if !isSelecting {
                        selectedIDs.removeAll()
                        viewModel.clearUndoState()
                    }
                }
            }

            ToolbarItem(placement: .automatic) {
                if !selectedIDs.isEmpty {
                    Button(bulkDeleteLabel) {
                        isShowingBulkDeleteConfirmation = true
                    }
                    .foregroundStyle(.red)
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
        .confirmationDialog(
            "Delete \(selectedIDs.count) selected item(s)?",
            isPresented: $isShowingBulkDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(bulkDeleteLabel, role: .destructive) {
                Task {
                    await viewModel.delete(ids: Array(selectedIDs))
                    selectedIDs.removeAll()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the selected items from local inventory and queues the delete for sync.")
        }
    }

    private var bulkDeleteLabel: String {
        "Delete \(selectedIDs.count) Item\(selectedIDs.count == 1 ? "" : "s")"
    }

    private func toggleSelection(for id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
}

private struct SellItemDraft {
    var title = ""
    var price: Decimal = 10
    var quantity = 1
    var detail = ""
}

private struct SellItemRow: View {
    let item: SellItem
    @State private var draft: SellItem
    @State private var sellAmount = 1
    let isSelecting: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onSave: (SellItem) -> Void
    let onSell: (SellItem, Int) -> Void

    init(
        item: SellItem,
        isSelecting: Bool,
        isSelected: Bool,
        onToggleSelection: @escaping () -> Void,
        onSave: @escaping (SellItem) -> Void,
        onSell: @escaping (SellItem, Int) -> Void
    ) {
        self.item = item
        _draft = State(initialValue: item)
        self.isSelecting = isSelecting
        self.isSelected = isSelected
        self.onToggleSelection = onToggleSelection
        self.onSave = onSave
        self.onSell = onSell
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if isSelecting {
                Button(action: onToggleSelection) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? .blue : .secondary)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(stockStateLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(stockStateColor)
                    Spacer()
                    Text("Updated \(draft.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TextField("Title", text: Binding(
                    get: { draft.title },
                    set: { draft = draft.with(title: $0) }
                ))
                TextField("Price", value: Binding(
                    get: { draft.askingPrice },
                    set: { draft = draft.with(price: $0) }
                ), format: .number)
                Stepper("Quantity: \(draft.quantity)", value: Binding(
                    get: { draft.quantity },
                    set: { draft = draft.with(quantity: $0) }
                ), in: 0...100)
                Picker("Lifecycle", selection: Binding(
                    get: { draft.status },
                    set: { draft = draft.with(status: $0) }
                )) {
                    Text("Active").tag(SellItemStatus.active)
                    Text("Archived").tag(SellItemStatus.archived)
                }
                .pickerStyle(.segmented)
                TextField("Detail", text: Binding(
                    get: { draft.detail },
                    set: { draft = draft.with(detail: $0) }
                ))
                VStack(alignment: .leading, spacing: 6) {
                    Stepper(
                        "Sell Amount: \(sellAmount)",
                        value: $sellAmount,
                        in: 1...max(draft.quantity, 1)
                    )
                    .disabled(!canSell)

                    Button("Confirm Sold") {
                        onSell(draft, sellAmount)
                    }
                    .disabled(!canSell)
                }
                Button("Save Changes") {
                    onSave(draft)
                }
            }
        }
        .padding(.vertical, 4)
        .onChange(of: item) { _, newItem in
            draft = newItem
            sellAmount = Self.defaultSellAmount(for: newItem)
        }
        .onChange(of: draft.quantity) { _, newQuantity in
            sellAmount = Self.clampedSellAmount(sellAmount, quantity: newQuantity)
        }
        .onChange(of: draft.status) { _, newStatus in
            if newStatus != .active {
                sellAmount = 1
            }
        }
    }

    private var stockStateLabel: String {
        if draft.status == .archived {
            return "Archived"
        }
        return draft.quantity == 0 ? "Sold Out" : "Available"
    }

    private var stockStateColor: Color {
        if draft.status == .archived {
            return .orange
        }
        return draft.quantity == 0 ? .green : .secondary
    }

    private var canSell: Bool {
        draft.status == .active && draft.quantity > 0
    }

    private static func defaultSellAmount(for item: SellItem) -> Int {
        1
    }

    private static func clampedSellAmount(_ amount: Int, quantity: Int) -> Int {
        guard quantity > 0 else { return 1 }
        return min(max(amount, 1), quantity)
    }
}

private extension SellItem {
    func with(
        title: String? = nil,
        price: Decimal? = nil,
        quantity: Int? = nil,
        detail: String? = nil,
        status: SellItemStatus? = nil
    ) -> SellItem {
        SellItem(
            id: id,
            title: title ?? self.title,
            askingPrice: price ?? askingPrice,
            quantity: quantity ?? self.quantity,
            detail: detail ?? self.detail,
            status: status ?? self.status,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
