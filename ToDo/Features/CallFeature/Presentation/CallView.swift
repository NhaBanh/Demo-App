import SwiftUI

struct CallView: View {
    @ObservedObject var viewModel: CallViewModel

    var body: some View {
        List {
            Section("People") {
                if let retryStatusMessage = viewModel.retryStatusMessage {
                    Text(retryStatusMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage = viewModel.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(errorMessage).foregroundStyle(.red)
                        Button("Retry") {
                            Task { await viewModel.retry() }
                        }
                    }
                } else {
                    ForEach(viewModel.people) { person in
                        CallPersonCard(person: person)
                    }
                }
            }

            Section("Pagination") {
                HStack {
                    Button("Previous") {
                        Task { await viewModel.previousPage() }
                    }
                    .disabled(viewModel.page == 1)

                    Spacer()
                    Text("Page \(viewModel.page) / \(viewModel.totalPages)")
                    Spacer()

                    Button("Next") {
                        Task { await viewModel.nextPage() }
                    }
                    .disabled(viewModel.page >= viewModel.totalPages)
                }

                if let lastSyncedAt = viewModel.lastSyncedAt {
                    Text("Last synced: \(lastSyncedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("To Call")
        .searchable(text: $viewModel.searchText, prompt: "Filter by name or phone")
        .onChange(of: viewModel.searchText) { _, _ in
            Task { await viewModel.searchTextDidChange() }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading people...")
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
