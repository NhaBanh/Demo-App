import Foundation

struct SQLiteSchemaManager {
    nonisolated init() {}

    func prepareDatabaseIfNeeded(
        database: SQLiteDatabase,
        pendingSyncStore: SQLitePendingSyncStore
    ) throws {
        guard !database.isOpen else { return }

        try database.open()
        try createTables(database: database, pendingSyncStore: pendingSyncStore)
        try migrateTablesIfNeeded(database: database, pendingSyncStore: pendingSyncStore)
        try createIndexes(database: database, pendingSyncStore: pendingSyncStore)
    }

    private func createTables(
        database: SQLiteDatabase,
        pendingSyncStore: SQLitePendingSyncStore
    ) throws {
        let createItemToSell = """
        CREATE TABLE IF NOT EXISTS ItemToSell (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL CHECK(length(trim(name)) > 0),
            askingPrice TEXT NOT NULL,
            quantity INTEGER NOT NULL CHECK(quantity >= 0),
            notes TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'active',
            isSold INTEGER NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            CHECK(CAST(askingPrice AS REAL) > 0)
        );
        """

        let createPendingSale = """
        CREATE TABLE IF NOT EXISTS \(pendingSyncStore.tableName) (
            id TEXT PRIMARY KEY,
            itemID TEXT NOT NULL,
            itemName TEXT NOT NULL,
            operationType TEXT NOT NULL DEFAULT 'sellOne',
            payload TEXT,
            queuedAt TEXT NOT NULL,
            retryCount INTEGER NOT NULL DEFAULT 0
        );
        """

        try database.execute(sql: createItemToSell)
        try database.execute(sql: createPendingSale)
    }

    private func migrateTablesIfNeeded(
        database: SQLiteDatabase,
        pendingSyncStore: SQLitePendingSyncStore
    ) throws {
        let itemColumns = try database.columnNames(in: "ItemToSell")
        if !itemColumns.contains("status") {
            try database.execute(sql: "ALTER TABLE ItemToSell ADD COLUMN status TEXT NOT NULL DEFAULT 'active';")
        }
        if !itemColumns.contains("createdAt") {
            let fallbackDate = database.dateString(from: .now)
            try database.execute(sql: "ALTER TABLE ItemToSell ADD COLUMN createdAt TEXT NOT NULL DEFAULT '\(fallbackDate)';")
            try database.execute(sql: "UPDATE ItemToSell SET createdAt = updatedAt WHERE createdAt = '\(fallbackDate)';")
        }

        let pendingColumns = try database.columnNames(in: pendingSyncStore.tableName)
        if !pendingColumns.contains("operationType") {
            try database.execute(sql: "ALTER TABLE \(pendingSyncStore.tableName) ADD COLUMN operationType TEXT NOT NULL DEFAULT 'sellOne';")
        }
        if !pendingColumns.contains("payload") {
            try database.execute(sql: "ALTER TABLE \(pendingSyncStore.tableName) ADD COLUMN payload TEXT;")
            try pendingSyncStore.backfillLegacyPendingPayloads(database: database)
        }
        if !pendingColumns.contains("retryCount") {
            try database.execute(sql: "ALTER TABLE \(pendingSyncStore.tableName) ADD COLUMN retryCount INTEGER NOT NULL DEFAULT 0;")
        }
    }

    private func createIndexes(
        database: SQLiteDatabase,
        pendingSyncStore: SQLitePendingSyncStore
    ) throws {
        try database.execute(sql: "CREATE INDEX IF NOT EXISTS idx_item_to_sell_updated_at ON ItemToSell(updatedAt DESC);")
        try database.execute(sql: "CREATE INDEX IF NOT EXISTS idx_item_to_sell_sold_updated_at ON ItemToSell(isSold, updatedAt DESC);")
        try database.execute(sql: "CREATE INDEX IF NOT EXISTS idx_pending_sale_sync_queued_at ON \(pendingSyncStore.tableName)(queuedAt DESC);")
    }
}
