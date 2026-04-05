import SwiftUI

struct SyncView: View {
    @ObservedObject var viewModel: SyncViewModel

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }

            Section("Pending Sell Sync") {
                if viewModel.queuedOperations.isEmpty {
                    Text("No pending sell changes.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.queuedOperations) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.payload?.title ?? item.itemID.uuidString).font(.headline)
                            Text(item.type.rawValue.capitalized)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("Queued for sync: \(item.queuedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Button {
                    Task { await viewModel.syncNow() }
                }
                label: {
                    HStack(spacing: 8) {
                        if viewModel.isSyncing {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("Sync Sell Changes")
                    }
                }
                .disabled(viewModel.queuedOperations.isEmpty || viewModel.isSyncing)
            }

            Section("Successful Sync This Session") {
                if viewModel.successfulOperations.isEmpty {
                    Text("No sync operations have succeeded yet in this session.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.successfulOperations) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.operation.payload?.title ?? item.operation.itemID.uuidString)
                                .font(.headline)
                            Text(syncOperationLabel(item.operation.type))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text("Synced: \(item.syncedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
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
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    private func syncOperationLabel(_ type: QueuedSellOperation.OperationType) -> String {
        switch type {
        case .create:
            "Create"
        case .update:
            "Update"
        case .delete:
            "Delete"
        }
    }
}
