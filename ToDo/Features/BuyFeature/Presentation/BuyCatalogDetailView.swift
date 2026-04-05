import SwiftUI

struct BuyCatalogDetailView: View {
    let item: BuyCatalogListItem
    let onSave: () -> Void

    var body: some View {
        List {
            Section("Item") {
                Text(item.item.title)
                    .font(.title3.weight(.semibold))
                Text(item.item.detail)
                detailAvailabilityMessage(for: item.item.availability)
                LabeledContent("Category", value: item.item.category.rawValue.capitalized)
                LabeledContent("Price") {
                    Text(item.item.price, format: .currency(code: "USD"))
                }
                LabeledContent("Availability", value: availabilityLabel(for: item.item.availability))
            }

            Section("Wishlist") {
                if item.isWishlisted {
                    Label("Saved to wishlist", systemImage: "heart.fill")
                        .foregroundStyle(.pink)
                    Text("Saved quantity: \(item.wishlistQuantity)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Open the Wishlist tab to change the quantity for this item.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if item.item.availability == .available {
                    Button("Save to Wishlist") {
                        onSave()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)

                    Text("Available stock: \(item.item.availableQuantity)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("You can adjust quantity later from the Wishlist screen.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("This item cannot be added to the wishlist while it is unavailable.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Detail")
    }

    @ViewBuilder
    private func detailAvailabilityMessage(for availability: BuyItemAvailability) -> some View {
        switch availability {
        case .available:
            EmptyView()
        case .outOfStock:
            Label("This item is currently out of stock.", systemImage: "exclamationmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(.orange)
        case .removedFromCatalog:
            Label("This item was removed from the catalog.", systemImage: "tray.fill")
                .font(.footnote)
                .foregroundStyle(.orange)
        }
    }
}

private func availabilityLabel(for availability: BuyItemAvailability) -> String {
    switch availability {
    case .available:
        "Available"
    case .outOfStock:
        "Out of stock"
    case .removedFromCatalog:
        "Removed from catalog"
    }
}
