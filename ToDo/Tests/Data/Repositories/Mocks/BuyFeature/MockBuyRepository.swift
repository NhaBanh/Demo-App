import Foundation

struct MockBuyRepository: BuyRepository {
    private let items: [BuyItem] = [
        .init(id: UUID(), title: "Printer Ink", detail: "Black cartridge for office printer.", price: 35, category: .office, availability: .available),
        .init(id: UUID(), title: "Standing Lamp", detail: "Warm light for the showroom corner.", price: 64, category: .household, availability: .available),
        .init(id: UUID(), title: "USB-C Dock", detail: "Docking hub for demo devices.", price: 120, category: .hardware, availability: .available),
        .init(id: UUID(), title: "Packaging Tape", detail: "Bulk tape rolls for shipments.", price: 16, category: .office, availability: .available),
        .init(id: UUID(), title: "Barcode Scanner", detail: "Compact scanner for inventory.", price: 89, category: .hardware, availability: .available),
        .init(id: UUID(), title: "Desk Organizer", detail: "Accessories tray for admin desk.", price: 24, category: .household, availability: .available),
        .init(id: UUID(), title: "Whiteboard Markers", detail: "Pack of dry-erase markers for planning sessions.", price: 14, category: .office, availability: .available),
        .init(id: UUID(), title: "Ethernet Switch", detail: "Eight-port switch for the demo room network.", price: 72, category: .hardware, availability: .available),
        .init(id: UUID(), title: "Storage Crates", detail: "Stackable crates for backroom organization.", price: 42, category: .household, availability: .available),
        .init(id: UUID(), title: "Thermal Labels", detail: "Replacement labels for the shipping printer.", price: 19, category: .office, availability: .outOfStock),
        .init(id: UUID(), title: "Mini Projector", detail: "Portable projector for pop-up product demos.", price: 210, category: .hardware, availability: .outOfStock),
        .init(id: UUID(), title: "Power Strip Tower", detail: "Multi-outlet surge protection for shared desks.", price: 38, category: .hardware, availability: .available),
        .init(id: UUID(), title: "Air Purifier Filter", detail: "Replacement filter for the office purifier.", price: 31, category: .household, availability: .available),
        .init(id: UUID(), title: "Archive Binders", detail: "Heavy-duty binders for contract storage.", price: 27, category: .office, availability: .available),
        .init(id: UUID(), title: "Wireless Presenter", detail: "Presentation remote with USB-C receiver.", price: 46, category: .hardware, availability: .available),
        .init(id: UUID(), title: "Floor Fan", detail: "High-velocity fan for the loading area.", price: 95, category: .household, availability: .outOfStock),
        .init(id: UUID(), title: "Legacy Label Printer", detail: "Older printer model retained for accessory replacement orders.", price: 150, category: .hardware, availability: .removedFromCatalog)
    ]

    func fetchItems(query: ToBuyCatalogQuery) async throws -> [BuyItem] {
        try await Task.sleep(for: .milliseconds(180))

        let searchText = query.searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        var filtered = if searchText.isEmpty {
            items
        } else {
            items.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.detail.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch query.sort {
        case .title:
            filtered.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .priceLowToHigh:
            filtered.sort { $0.price < $1.price }
        case .priceHighToLow:
            filtered.sort { $0.price > $1.price }
        }

        return filtered
    }

    func totalCount() async throws -> Int {
        items.count
    }
}
