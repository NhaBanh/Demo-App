import SwiftUI

struct WishlistItemRow: View {
    let record: WishlistItemRecord
    let onIncrease: () -> Void
    let onDecrease: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.item.title)
                    .font(.headline)
                Text(record.item.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                wishlistAvailabilityBadge(for: record.item.availability)
                Label(record.item.category.rawValue.capitalized, systemImage: "tag")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(record.item.price, format: .currency(code: "USD"))
                    .font(.subheadline.weight(.semibold))
                Text(stockCaption)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            WishlistQuantityControl(
                quantity: record.quantity,
                maxQuantity: record.item.availability == .available ? record.item.availableQuantity : 0,
                onIncrease: onIncrease,
                onDecrease: onDecrease
            )
        }
    }

    private var stockCaption: String {
        switch record.item.availability {
        case .available:
            "Available stock: \(record.item.availableQuantity)"
        case .outOfStock:
            "Currently out of stock. You can still reduce the saved quantity."
        case .removedFromCatalog:
            "Removed from catalog. You can still reduce the saved quantity."
        }
    }
}

@ViewBuilder
private func wishlistAvailabilityBadge(for availability: BuyItemAvailability) -> some View {
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
