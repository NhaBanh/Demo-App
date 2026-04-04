import SwiftUI

struct ToBuyDetailView: View {
    let item: ToBuyListItem
    let onIncrease: () -> Void
    let onDecrease: () -> Void
    @State private var quantity: Int

    init(item: ToBuyListItem, onIncrease: @escaping () -> Void, onDecrease: @escaping () -> Void) {
        self.item = item
        self.onIncrease = onIncrease
        self.onDecrease = onDecrease
        _quantity = State(initialValue: item.wishlistQuantity)
    }

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

            Section("Wishlist Quantity") {
                if item.item.availability == .available {
                    WishlistQuantityControl(
                        quantity: quantity,
                        onIncrease: {
                            quantity += 1
                            onIncrease()
                        },
                        onDecrease: {
                            guard quantity > 0 else { return }
                            quantity -= 1
                            onDecrease()
                        }
                    )

                    Text(quantity == 0 ? "This item is not in the wishlist yet." : "Planned quantity: \(quantity)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Wishlist quantity can only be changed while the item is available.")
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
