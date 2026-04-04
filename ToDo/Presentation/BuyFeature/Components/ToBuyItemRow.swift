import SwiftUI

struct ToBuyItemRow: View {
    let item: ToBuyListItem
    let onOpen: () -> Void
    let onIncrease: () -> Void
    let onDecrease: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.item.title)
                        .font(.headline)
                    Text(item.item.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    availabilityBadge(for: item.item.availability)
                    Label(item.item.category.rawValue.capitalized, systemImage: "tag")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.item.price, format: .currency(code: "USD"))
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            if item.item.availability == .available {
                WishlistQuantityControl(
                    quantity: item.wishlistQuantity,
                    onIncrease: onIncrease,
                    onDecrease: onDecrease
                )
            }
        }
    }
}

@ViewBuilder
private func availabilityBadge(for availability: BuyItemAvailability) -> some View {
    switch availability {
    case .available:
        EmptyView()
    case .outOfStock:
        Label("Out of stock", systemImage: "exclamationmark.circle.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.orange)
    case .removedFromCatalog:
        Label("Removed from catalog", systemImage: "tray.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.orange)
    }
}

struct WishlistQuantityControl: View {
    let quantity: Int
    let onIncrease: () -> Void
    let onDecrease: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Button(action: onDecrease) {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .disabled(quantity == 0)
            
            Text("\(quantity)")
                .font(.headline.monospacedDigit())
                .frame(minWidth: 24)
            
            Button(action: onIncrease) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(quantity > 0 ? .pink : .secondary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Wishlist quantity")
        .accessibilityValue("\(quantity)")
    }
}
