import SwiftUI

struct RootView: View {
    let container: AppContainer
    @State private var selectedTab: AppTab = .toCall

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ToCallView(viewModel: container.makeToCallViewModel())
            }
            .tabItem {
                Label("To Call", systemImage: "phone")
            }
            .tag(AppTab.toCall)

            NavigationStack {
                ToBuyView(viewModel: container.makeToBuyViewModel())
            }
            .tabItem {
                Label("To Buy", systemImage: "cart")
            }
            .tag(AppTab.toBuy)

            NavigationStack {
                ToSellView(viewModel: container.makeToSellViewModel())
            }
            .tabItem {
                Label("To Sell", systemImage: "tag")
            }
            .tag(AppTab.toSell)

            NavigationStack {
                SyncView(viewModel: container.makeSyncViewModel())
            }
            .tabItem {
                Label("Sync", systemImage: "arrow.triangle.2.circlepath")
            }
            .tag(AppTab.sync)
        }
    }
}

private enum AppTab: Hashable {
    case toCall
    case toBuy
    case toSell
    case sync
}
