import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    let container: AppContainer

    init(viewModel: HomeViewModel, container: AppContainer) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.container = container
    }

    var body: some View {
        List {
            Section("Overview") {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }

                CounterRow(title: "To Call", count: viewModel.counts.toCall, systemImage: "phone")
                CounterRow(title: "To Buy", count: viewModel.counts.toBuy, systemImage: "cart")
                CounterRow(title: "To Sell", count: viewModel.counts.toSell, systemImage: "tag")
                CounterRow(title: "Pending Sync", count: viewModel.counts.pendingSync, systemImage: "arrow.triangle.2.circlepath")
            }

            Section("Modules") {
                NavigationLink("To Call") {
                    ToCallView(viewModel: container.makeToCallViewModel())
                }

                NavigationLink("To Buy") {
                    ToBuyView(viewModel: container.makeToBuyViewModel())
                }

                NavigationLink("To Sell") {
                    ToSellView(viewModel: container.makeToSellViewModel())
                }

                NavigationLink("Sync") {
                    SyncView(viewModel: container.makeSyncViewModel())
                }
            }
        }
        .navigationTitle("To-do App")
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading dashboard...")
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .allowsHitTesting(false)
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }
}

private struct CounterRow: View {
    let title: String
    let count: Int
    let systemImage: String

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
            Spacer()
            Text("\(count)")
                .font(.headline)
        }
    }
}
