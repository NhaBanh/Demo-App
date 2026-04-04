import SwiftUI

struct ToCallView: View {
    @StateObject private var viewModel: ToCallViewModel

    init(viewModel: ToCallViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section("Filters") {
                TextField("Search name, company, or phone number", text: $viewModel.filter)
            }

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
                        ToCallPersonCard(person: person)
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
