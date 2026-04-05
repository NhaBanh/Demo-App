import Foundation

actor MockInventoryServer {
    private static let responseDelay = Duration.seconds(2)

    struct BuyItemsPageDTO {
        let items: [RemoteBuyItemDTO]
        let page: Int
        let pageSize: Int
        let totalCount: Int
        let hasMore: Bool
    }

    private var inventoryItemsByID: [UUID: RemoteInventoryItemDTO]

    init(
        inventoryItems: [RemoteInventoryItemDTO] = MockInventoryServer.defaultInventoryItems()
    ) {
        inventoryItemsByID = Dictionary(uniqueKeysWithValues: inventoryItems.map { ($0.id, $0) })
    }

    func fetchBuyItems(query: BuyCatalogQuery) async throws -> BuyItemsPageDTO {
        try await Task.sleep(for: Self.responseDelay)

        var filtered = Array(inventoryItemsByID.values)
        if let availability = query.availability {
            filtered = filtered.filter { $0.availability == remoteAvailability(for: availability) }
        }
        if let category = query.category {
            filtered = filtered.filter { $0.category == category }
        }

        filtered.sort { lhs, rhs in
            let availabilityComparison = availabilityRank(for: lhs.availability) - availabilityRank(for: rhs.availability)
            if availabilityComparison != 0 {
                return availabilityComparison < 0
            }

            switch query.sort {
            case .title:
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            case .priceLowToHigh:
                if lhs.price == rhs.price {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return lhs.price < rhs.price
            case .priceHighToLow:
                if lhs.price == rhs.price {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return lhs.price > rhs.price
            }
        }

        let sanitizedPage = max(1, query.page)
        let sanitizedPageSize = max(1, query.pageSize)
        let totalCount = filtered.count
        let offset = (sanitizedPage - 1) * sanitizedPageSize
        let pageItems = Array(filtered.dropFirst(offset).prefix(sanitizedPageSize))

        return BuyItemsPageDTO(
            items: pageItems.map(RemoteBuyItemDTO.init),
            page: sanitizedPage,
            pageSize: sanitizedPageSize,
            totalCount: totalCount,
            hasMore: offset + pageItems.count < totalCount
        )
    }

    func fetchBuyItems(ids: [UUID]) async throws -> [RemoteBuyItemDTO] {
        try await Task.sleep(for: Self.responseDelay)
        return ids.compactMap { inventoryItemsByID[$0] }.map(RemoteBuyItemDTO.init)
    }

    func fetchBuyItem(title: String, category: BuyCategory) async throws -> RemoteBuyItemDTO? {
        try await Task.sleep(for: Self.responseDelay)

        return inventoryItemsByID.values
            .first {
                $0.category == category &&
                $0.title.localizedCaseInsensitiveCompare(title) == .orderedSame
            }
            .map(RemoteBuyItemDTO.init)
    }

    private func availabilityRank(for availability: RemoteBuyAvailabilityDTO) -> Int {
        switch availability {
        case .available:
            0
        case .outOfStock:
            1
        case .removedFromCatalog:
            2
        }
    }

    private func remoteAvailability(for availability: BuyItemAvailability) -> RemoteBuyAvailabilityDTO {
        switch availability {
        case .available:
            .available
        case .outOfStock:
            .outOfStock
        case .removedFromCatalog:
            .removedFromCatalog
        }
    }

    func totalBuyItemCount() -> Int {
        inventoryItemsByID.count
    }

    func fetchSellItems() async throws -> [RemoteSellItemDTO] {
        try await Task.sleep(for: Self.responseDelay)
        return inventoryItemsByID.values
            .sorted { $0.updatedAt > $1.updatedAt }
            .map(RemoteSellItemDTO.init)
    }

    func createSellItem(_ item: RemoteSellItemDTO) async throws {
        try await Task.sleep(for: Self.responseDelay)
        inventoryItemsByID[item.id] = RemoteInventoryItemDTO(sellItem: item, existing: inventoryItemsByID[item.id])
    }

    func updateSellItem(_ item: RemoteSellItemDTO) async throws {
        try await Task.sleep(for: Self.responseDelay)
        inventoryItemsByID[item.id] = RemoteInventoryItemDTO(sellItem: item, existing: inventoryItemsByID[item.id])
    }

    func deleteSellItem(id: UUID) async throws {
        try await Task.sleep(for: Self.responseDelay)
        inventoryItemsByID.removeValue(forKey: id)
    }

    func sellOneSellItem(id: UUID) async throws {
        try await Task.sleep(for: Self.responseDelay)
        guard let existing = inventoryItemsByID[id] else { return }

        inventoryItemsByID[id] = existing.sellingOne(at: .now)
    }
}

private extension MockInventoryServer {
    static func defaultInventoryItems() -> [RemoteInventoryItemDTO] {
        let now = Date.now

        return [
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000001"), "Printer Ink", detail: "Black cartridge for office printer.", price: 35, category: .office, availability: .available, quantity: 12, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000002"), "Standing Lamp", detail: "Warm light for the showroom corner.", price: 64, category: .household, availability: .available, quantity: 4, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000003"), "USB-C Dock", detail: "Docking hub for demo devices.", price: 120, category: .hardware, availability: .available, quantity: 6, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000004"), "Packaging Tape", detail: "Bulk tape rolls for shipments.", price: 16, category: .office, availability: .available, quantity: 20, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000005"), "Barcode Scanner", detail: "Compact scanner for inventory.", price: 89, category: .hardware, availability: .available, quantity: 3, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000006"), "Desk Organizer", detail: "Accessories tray for admin desk.", price: 24, category: .household, availability: .available, quantity: 8, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000007"), "Whiteboard Markers", detail: "Pack of dry-erase markers for planning sessions.", price: 14, category: .office, availability: .available, quantity: 15, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000008"), "Ethernet Switch", detail: "Eight-port switch for the demo room network.", price: 72, category: .hardware, availability: .available, quantity: 5, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000009"), "Storage Crates", detail: "Stackable crates for backroom organization.", price: 42, category: .household, availability: .available, quantity: 10, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-00000000000A"), "Shipping Scale", detail: "Digital scale for weighing outgoing parcels.", price: 58, category: .office, availability: .available, quantity: 7, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-00000000000B"), "Portable SSD", detail: "Fast external drive for media transfer kits.", price: 99, category: .hardware, availability: .available, quantity: 6, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-00000000000C"), "Cable Clips", detail: "Adhesive clips for organizing desk wiring.", price: 9, category: .household, availability: .available, quantity: 25, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-00000000000D"), "Ring Light", detail: "Adjustable lighting for livestream demos.", price: 54, category: .hardware, availability: .available, quantity: 4, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-00000000000E"), "Invoice Paper", detail: "Perforated paper stock for receipt printing.", price: 22, category: .office, availability: .available, quantity: 18, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-00000000000F"), "Toolbox Set", detail: "Compact repair kit for fixture maintenance.", price: 68, category: .household, availability: .available, quantity: 5, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000010"), "Laptop Stand", detail: "Aluminum riser for checkout and admin stations.", price: 33, category: .hardware, availability: .available, quantity: 9, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000011"), "Sticky Notes", detail: "Color-coded note pads for warehouse labeling.", price: 11, category: .office, availability: .available, quantity: 30, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000012"), "Display Risers", detail: "Acrylic risers for front-of-store product displays.", price: 47, category: .household, availability: .available, quantity: 6, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000013"), "Thermal Labels", detail: "Replacement labels for the shipping printer.", price: 19, category: .office, availability: .outOfStock, quantity: 0, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000014"), "Mini Projector", detail: "Portable projector for pop-up product demos.", price: 210, category: .hardware, availability: .outOfStock, quantity: 0, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000015"), "Power Strip Tower", detail: "Multi-outlet surge protection for shared desks.", price: 38, category: .hardware, availability: .available, quantity: 9, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000016"), "Air Purifier Filter", detail: "Replacement filter for the office purifier.", price: 31, category: .household, availability: .available, quantity: 7, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000017"), "Archive Binders", detail: "Heavy-duty binders for contract storage.", price: 27, category: .office, availability: .available, quantity: 11, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000018"), "Wireless Presenter", detail: "Presentation remote with USB-C receiver.", price: 46, category: .hardware, availability: .available, quantity: 2, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000019"), "Floor Fan", detail: "High-velocity fan for the loading area.", price: 95, category: .household, availability: .outOfStock, quantity: 0, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-00000000001A"), "Receipt Paper", detail: "Register paper rolls awaiting the next supplier batch.", price: 13, category: .office, availability: .outOfStock, quantity: 0, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-00000000001B"), "Mesh Router Node", detail: "Expansion node for the showroom Wi-Fi network.", price: 129, category: .hardware, availability: .outOfStock, quantity: 0, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-00000000001C"), "Cleaning Caddy", detail: "Portable caddy used for after-hours store resets.", price: 29, category: .household, availability: .outOfStock, quantity: 0, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-00000000001D"), "Legacy Label Printer", detail: "Older printer model retained for accessory replacement orders.", price: 150, category: .hardware, availability: .removedFromCatalog, quantity: 1, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-00000000001E"), "Archive Cart", detail: "Discontinued rolling cart from the old records room setup.", price: 84, category: .household, availability: .removedFromCatalog, quantity: 0, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-00000000001F"), "POS Keyboard", detail: "Retired keyboard model replaced by the new checkout bundle.", price: 44, category: .hardware, availability: .removedFromCatalog, quantity: 0, now: now),
            makeDefaultItem(id: fixedUUID("10000000-0000-0000-0000-000000000020"), "Fax Toner", detail: "Old toner line kept only for past procurement references.", price: 26, category: .office, availability: .removedFromCatalog, quantity: 0, now: now)
        ]
    }

    static func makeDefaultItem(
        id: UUID = UUID(),
        _ title: String,
        detail: String,
        price: Decimal,
        category: BuyCategory,
        availability: RemoteBuyAvailabilityDTO,
        quantity: Int,
        now: Date
    ) -> RemoteInventoryItemDTO {
        RemoteInventoryItemDTO(
            id: id,
            title: title,
            detail: detail,
            price: price,
            category: category,
            availability: availability,
            quantity: quantity,
            status: .active,
            createdAt: now,
            updatedAt: now
        )
    }

    static func fixedUUID(_ value: String) -> UUID {
        guard let uuid = UUID(uuidString: value) else {
            preconditionFailure("Invalid fixed UUID: \(value)")
        }
        return uuid
    }
}
