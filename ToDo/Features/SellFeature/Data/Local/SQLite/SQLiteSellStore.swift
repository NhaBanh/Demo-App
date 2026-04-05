import Foundation

actor SQLiteSellStore {
    private static let pendingSyncTable = "PendingSaleSync"
    private let database: SQLiteDatabase
    private let schemaManager = SQLiteSchemaManager()
    private let sellItemStore = SQLiteSellItemStore()
    private let pendingSyncStore = SQLitePendingSyncStore(tableName: pendingSyncTable)

    init(filename: String = "todo.sqlite") {
        database = SQLiteDatabase(filename: filename)
    }

    func fetchSellItems(query: SellItemsQuery) throws -> SellItemsPage {
        try openIfNeeded()
        return try sellItemStore.fetchSellItems(query: query, database: database)
    }

    func fetchSellItem(id: UUID) throws -> SellItem? {
        try openIfNeeded()
        return try sellItemStore.fetchSellItem(id: id, database: database)
    }

    func fetchSellItems(ids: [UUID]) throws -> [SellItem] {
        try openIfNeeded()
        return try sellItemStore.fetchSellItems(ids: ids, database: database)
    }

    func insertSellItem(_ item: SellItem) throws {
        try openIfNeeded()
        try sellItemStore.insertSellItem(item, database: database)
    }

    func insertSellItemAndQueueCreate(_ item: SellItem) throws {
        try openIfNeeded()
        try database.inTransaction {
            try sellItemStore.insertSellItem(item, database: database)
            try pendingSyncStore.queuePendingOperation(type: .create, item: item, queueID: UUID(), database: database)
        }
    }

    func updateSellItem(_ item: SellItem) throws {
        try openIfNeeded()
        try sellItemStore.updateSellItem(item, database: database)
    }

    func updateSellItemAndQueue(_ item: SellItem, type: QueuedSellOperation.OperationType) throws {
        try openIfNeeded()
        try database.inTransaction {
            try sellItemStore.updateSellItem(item, database: database)
            try pendingSyncStore.queuePendingOperation(type: type, item: item, queueID: UUID(), database: database)
        }
    }

    func upsertSellItems(_ items: [SellItem]) throws {
        try openIfNeeded()
        try sellItemStore.upsertSellItems(items, database: database)
    }

    func deleteSellItems(ids: [UUID]) throws {
        try openIfNeeded()
        try sellItemStore.deleteSellItems(ids: ids, database: database)
    }

    func deleteSellItemsAndQueue(_ items: [SellItem]) throws {
        try openIfNeeded()
        try database.inTransaction {
            try sellItemStore.deleteSellItems(ids: items.map(\.id), database: database)
            for item in items {
                try pendingSyncStore.queuePendingOperation(type: .delete, item: item, queueID: UUID(), database: database)
            }
        }
    }

    func queuePendingOperation(type: QueuedSellOperation.OperationType, item: SellItem, queueID: UUID) throws {
        try openIfNeeded()
        try pendingSyncStore.queuePendingOperation(type: type, item: item, queueID: queueID, database: database)
    }

    func fetchPendingOperations() throws -> [QueuedSellOperation] {
        try openIfNeeded()
        return try pendingSyncStore.fetchPendingOperations(database: database)
    }

    func clearPendingSales(ids: [UUID]) throws {
        try openIfNeeded()
        try pendingSyncStore.clearPendingSales(ids: ids, database: database)
    }

    func totalSellCount() throws -> Int {
        try openIfNeeded()
        return try sellItemStore.totalSellCount(database: database)
    }

    func totalPendingCount() throws -> Int {
        try openIfNeeded()
        return try pendingSyncStore.totalPendingCount(database: database)
    }

    private func openIfNeeded() throws {
        try schemaManager.prepareDatabaseIfNeeded(database: database, pendingSyncStore: pendingSyncStore)
    }
}
