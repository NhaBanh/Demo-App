import SwiftUI

struct HomeView: View {
    let summary: HomeSummary
    let onSelectModule: (AppModule) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Choose a module")
                    .font(.title2.weight(.semibold))
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 16) {
                    HomeModuleCard(
                        title: "To Call",
                        systemImage: "phone",
                        summaryLines: [
                            "\(summary.call.hotCount) hot",
                            "\(summary.call.warmCount) warm",
                            "\(summary.call.coldCount) cold"
                        ],
                        action: { onSelectModule(.toCall) }
                    )

                    HomeModuleCard(
                        title: "To Buy",
                        systemImage: "cart",
                        summaryLines: [
                            "\(summary.buy.availableCount) available",
                            "\(summary.buy.outOfStockCount) out of stock",
                            "\(summary.buy.wishlistCount) wishlisted"
                        ],
                        action: { onSelectModule(.toBuy) }
                    )

                    HomeModuleCard(
                        title: "To Sell",
                        systemImage: "tag",
                        summaryLines: [
                            "\(summary.sell.totalSellItems) total items",
                            "Local inventory"
                        ],
                        action: { onSelectModule(.toSell) }
                    )

                    HomeModuleCard(
                        title: "Sync",
                        systemImage: "arrow.triangle.2.circlepath",
                        summaryLines: [
                            "\(summary.sync.pendingCount) pending",
                            "\(summary.sync.sessionSuccessCount) synced this session"
                        ],
                        action: { onSelectModule(.sync) }
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Home")
    }
}

private struct HomeModuleCard: View {
    let title: String
    let systemImage: String
    let summaryLines: [String]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.title2)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(title)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(summaryLines, id: \.self) { line in
                        Text(line)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

enum AppModule: Hashable {
    case toCall
    case toBuy
    case toSell
    case sync
}
