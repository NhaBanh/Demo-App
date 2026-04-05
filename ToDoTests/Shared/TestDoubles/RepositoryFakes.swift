import Foundation
import Combine
@testable import ToDo

final class BuyRepositoryFake: BuyRepository {
    var fetchItemsResult: Result<BuyItemsPage, Error> = .success(
        BuyItemsPage(items: [], page: 1, pageSize: 20, totalCount: 0, hasMore: false)
    )
    var totalCountResult: Result<Int, Error> = .success(0)
    var fetchItemsHandler: ((BuyCatalogQuery) async throws -> BuyItemsPage)?
    private(set) var receivedQueries: [BuyCatalogQuery] = []

    func fetchItems(query: BuyCatalogQuery) async throws -> BuyItemsPage {
        receivedQueries.append(query)
        if let fetchItemsHandler {
            return try await fetchItemsHandler(query)
        }
        return try fetchItemsResult.get()
    }

    func totalCount() async throws -> Int {
        try totalCountResult.get()
    }
}

final class WishlistRepositoryFake: WishlistRepository {
    var records: [WishlistItemRecord] = []
    var setQuantityResult: Result<Int, Error> = .success(0)
    var refreshSnapshotsError: Error?
    var refreshSnapshotsHandler: (() async throws -> Void)?
    private(set) var refreshSnapshotsCallCount = 0
    private(set) var setQuantityCalls: [(item: BuyItem, quantity: Int)] = []

    func wishlistRecords() throws -> [WishlistItemRecord] {
        records
    }

    func setQuantity(for item: BuyItem, quantity: Int) throws -> Int {
        setQuantityCalls.append((item, quantity))
        let result = try setQuantityResult.get()
        if let existingIndex = records.firstIndex(where: { $0.item.id == item.id }) {
            if result == 0 {
                records.remove(at: existingIndex)
            } else {
                records[existingIndex] = WishlistItemRecord(
                    item: item,
                    quantity: result,
                    createdAt: records[existingIndex].createdAt
                )
            }
        } else if result > 0 {
            records.append(WishlistItemRecord(item: item, quantity: result, createdAt: .now))
        }
        return result
    }

    func refreshSnapshots() async throws {
        refreshSnapshotsCallCount += 1
        if let refreshSnapshotsHandler {
            try await refreshSnapshotsHandler()
        }
        if let refreshSnapshotsError {
            throw refreshSnapshotsError
        }
    }
}

final class SellRepositoryFake: SellRepository {
    var fetchItemsResult: Result<SellItemsPage, Error> = .success(
        SellItemsPage(items: [], page: 1, pageSize: 20, totalCount: 0, hasMore: false)
    )
    var fetchItemResult: Result<SellItem?, Error> = .success(nil)
    var createResult: Result<SellItem, Error> = .success(.fixture())
    var updateResult: Result<SellItem, Error> = .success(.fixture())
    var deleteResult: Result<[SellItem], Error> = .success([])
    var restoreError: Error?
    var totalCountResult: Result<Int, Error> = .success(0)
    var fetchItemsHandler: ((SellItemsQuery) async throws -> SellItemsPage)?

    private(set) var receivedFetchQueries: [SellItemsQuery] = []
    private(set) var receivedFetchIDs: [UUID] = []
    private(set) var receivedCreatedItems: [SellItem] = []
    private(set) var receivedUpdatedItems: [SellItem] = []
    private(set) var receivedDeleteIDs: [[UUID]] = []
    private(set) var receivedRestoreItems: [[SellItem]] = []

    func fetchItems(query: SellItemsQuery) async throws -> SellItemsPage {
        receivedFetchQueries.append(query)
        if let fetchItemsHandler {
            return try await fetchItemsHandler(query)
        }
        return try fetchItemsResult.get()
    }

    func fetchItem(id: UUID) async throws -> SellItem? {
        receivedFetchIDs.append(id)
        return try fetchItemResult.get()
    }

    func create(_ item: SellItem) async throws -> SellItem {
        receivedCreatedItems.append(item)
        return try createResult.get()
    }

    func update(_ item: SellItem) async throws -> SellItem {
        receivedUpdatedItems.append(item)
        return try updateResult.get()
    }

    func delete(ids: [UUID]) async throws -> [SellItem] {
        receivedDeleteIDs.append(ids)
        return try deleteResult.get()
    }

    func restore(items: [SellItem]) async throws {
        receivedRestoreItems.append(items)
        if let restoreError {
            throw restoreError
        }
    }

    func totalCount() async throws -> Int {
        try totalCountResult.get()
    }
}

final class SyncRepositoryFake: SyncRepository {
    var pendingOperationsResult: Result<[QueuedSellOperation], Error> = .success([])
    var pendingCountResult: Result<Int, Error> = .success(0)
    var syncPendingChangesResult: Result<[QueuedSellOperation], Error> = .success([])
    private(set) var syncPendingChangesCallCount = 0

    func pendingSyncOperations() async throws -> [QueuedSellOperation] {
        try pendingOperationsResult.get()
    }

    func pendingSyncCount() async throws -> Int {
        try pendingCountResult.get()
    }

    func syncPendingChanges() async throws -> [QueuedSellOperation] {
        syncPendingChangesCallCount += 1
        return try syncPendingChangesResult.get()
    }
}

final class CallRepositoryFake: CallRepository {
    struct PageRequest: Equatable {
        let page: Int
        let pageSize: Int
        let searchText: String?
    }

    var fetchPeopleResult: Result<CallPage, Error> = .success(
        CallPage(items: [], page: 1, totalPages: 1, lastSyncedAt: .now)
    )
    var totalCountResult: Result<Int, Error> = .success(0)
    var fetchPeopleHandler: ((Int, Int, String?) async throws -> CallPage)?
    private(set) var receivedPageRequests: [PageRequest] = []

    func fetchPeople(page: Int, pageSize: Int, searchText: String?) async throws -> CallPage {
        receivedPageRequests.append(
            PageRequest(page: page, pageSize: pageSize, searchText: searchText)
        )
        if let fetchPeopleHandler {
            return try await fetchPeopleHandler(page, pageSize, searchText)
        }
        return try fetchPeopleResult.get()
    }

    func totalCount() async throws -> Int {
        try totalCountResult.get()
    }
}

final class ConnectivityMonitorFake: ConnectivityMonitoring {
    private let subject: CurrentValueSubject<Bool, Never>

    var isConnected: Bool {
        subject.value
    }

    var connectivityPublisher: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    init(isConnected: Bool = true) {
        subject = CurrentValueSubject(isConnected)
    }

    func send(_ isConnected: Bool) {
        subject.send(isConnected)
    }
}

extension BuyItem {
    static func fixture(
        id: UUID = UUID(),
        title: String = "Printer Ink",
        detail: String = "Black cartridge",
        price: Decimal = 35,
        category: BuyCategory = .office,
        availability: BuyItemAvailability = .available,
        availableQuantity: Int = 5
    ) -> BuyItem {
        BuyItem(
            id: id,
            title: title,
            detail: detail,
            price: price,
            category: category,
            availability: availability,
            availableQuantity: availableQuantity
        )
    }
}

extension WishlistItemRecord {
    static func fixture(
        item: BuyItem = .fixture(),
        quantity: Int = 1,
        createdAt: Date = .now
    ) -> WishlistItemRecord {
        WishlistItemRecord(item: item, quantity: quantity, createdAt: createdAt)
    }
}

extension BuyCatalogListItem {
    static func fixture(
        item: BuyItem = .fixture(),
        wishlistQuantity: Int = 0
    ) -> BuyCatalogListItem {
        BuyCatalogListItem(item: item, wishlistQuantity: wishlistQuantity)
    }
}

extension SellItem {
    static func fixture(
        id: UUID = UUID(),
        title: String = "Desk Lamp",
        askingPrice: Decimal = 49,
        quantity: Int = 3,
        detail: String = "Warm light",
        status: SellItemStatus = .active,
        createdAt: Date = .now.addingTimeInterval(-300),
        updatedAt: Date = .now
    ) -> SellItem {
        SellItem(
            id: id,
            title: title,
            askingPrice: askingPrice,
            quantity: quantity,
            detail: detail,
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension QueuedSellOperation {
    static func fixture(
        id: UUID = UUID(),
        itemID: UUID = UUID(),
        type: OperationType = .update,
        payload: SellItem? = .fixture(),
        queuedAt: Date = .now,
        retryCount: Int = 0
    ) -> QueuedSellOperation {
        QueuedSellOperation(
            id: id,
            itemID: itemID,
            type: type,
            payload: payload,
            queuedAt: queuedAt,
            retryCount: retryCount
        )
    }
}

@MainActor
func makeHomeSummaryViewModel(
    sellRepository: SellRepository = SellRepositoryFake(),
    syncRepository: SyncRepository = SyncRepositoryFake(),
    wishlistRepository: WishlistRepository = WishlistRepositoryFake(),
    connectivityMonitor: ConnectivityMonitoring = ConnectivityMonitorFake()
) -> HomeSummaryViewModel {
    let orchestrator = SyncOrchestrator(
        syncRepository: syncRepository,
        connectivityMonitor: connectivityMonitor
    )

    return HomeSummaryViewModel(
        sellRepository: sellRepository,
        syncRepository: syncRepository,
        wishlistRepository: wishlistRepository,
        syncOrchestrator: orchestrator
    )
}

extension PersonToCall {
    static func fixture(
        id: UUID = UUID(),
        name: String = "Ava Nguyen",
        phoneNumbers: [String] = ["090-111-2222"],
        company: String = "Northern Labs",
        priority: CallPriority = .hot,
        lastContactedAt: Date? = nil,
        notes: String = "Follow up",
        preferredContactTime: Date? = nil,
        email: String? = nil
    ) -> PersonToCall {
        PersonToCall(
            id: id,
            name: name,
            phoneNumbers: phoneNumbers,
            company: company,
            priority: priority,
            lastContactedAt: lastContactedAt,
            notes: notes,
            preferredContactTime: preferredContactTime,
            email: email
        )
    }
}
