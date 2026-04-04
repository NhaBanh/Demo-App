import SwiftUI

struct SyncView: View {
    @StateObject private var viewModel: SyncViewModel

    init(viewModel: SyncViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }

            Section("Sell Actions Ready To Queue") {
                ForEach(viewModel.sellItems) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name).font(.headline)
                            Text(item.askingPrice, format: .currency(code: "USD"))
                        }
                        Spacer()
                        Button("Sell") {
                            Task { await viewModel.markSold(itemID: item.id) }
                        }
                    }
                }
            }

            Section("Pending Sell Sync") {
                if viewModel.pendingItems.isEmpty {
                    Text("No pending sell changes.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.pendingItems) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.itemName).font(.headline)
                            Text("Queued for sync: \(item.queuedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Button("Sync Sell Changes") {
                    Task { await viewModel.syncNow() }
                }
                .disabled(viewModel.pendingItems.isEmpty)
            }

            if let toastMessage = viewModel.toastMessage {
                Section {
                    Text(toastMessage)
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("Sync")
        .overlay {
            if viewModel.isLoading {
                ProgressView("Refreshing sync state...")
            }
        }
        .task {
            await viewModel.refresh()
            await viewModel.syncNow()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}
