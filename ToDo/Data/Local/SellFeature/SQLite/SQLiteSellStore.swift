import Foundation
import SQLite3

actor SQLiteSellStore {
    private static let pendingSyncTable = "PendingSaleSync"
    private let isoFormatter = ISO8601DateFormatter()
    private let databaseURL: URL
    private var db: OpaquePointer?

    init(filename: String = "todo.sqlite") {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        databaseURL = documentsURL.appendingPathComponent(filename)
    }

    deinit {
        sqlite3_close(db)
    }

    func fetchSellItems(query: SellItemsQuery) throws -> SellItemsPage {
        try openIfNeeded()

        let sanitizedPage = max(1, query.page)
        let sanitizedPageSize = max(1, query.pageSize)
        let whereClause = buildWhereClause(for: query)
        let orderClause = buildOrderClause(for: query)
        let offset = (sanitizedPage - 1) * sanitizedPageSize

        let totalCount = try countSellItems(whereClause: whereClause.sql, parameters: whereClause.parameters)
        let sql = """
        SELECT id, name, askingPrice, quantity, notes, isSold, createdAt, updatedAt
        FROM ItemToSell
        \(whereClause.sql)
        \(orderClause)
        LIMIT ? OFFSET ?;
        """

        var parameters = whereClause.parameters
        parameters.append(.int(sanitizedPageSize))
        parameters.append(.int(offset))

        let items = try fetchItems(sql: sql, parameters: parameters)
        let loadedCount = offset + items.count

        return SellItemsPage(
            items: items,
            page: sanitizedPage,
            pageSize: sanitizedPageSize,
            totalCount: totalCount,
            hasMore: loadedCount < totalCount
        )
    }

    func fetchSellItem(id: UUID) throws -> SellItem? {
        try openIfNeeded()
        let items = try fetchItems(
            sql: """
            SELECT id, name, askingPrice, quantity, notes, isSold, createdAt, updatedAt
            FROM ItemToSell
            WHERE id = ?
            LIMIT 1;
            """,
            parameters: [.text(id.uuidString)]
        )
        return items.first
    }

    func fetchSellItems(ids: [UUID]) throws -> [SellItem] {
        guard !ids.isEmpty else { return [] }
        try openIfNeeded()
        let placeholders = Array(repeating: "?", count: ids.count).joined(separator: ", ")
        let sql = """
        SELECT id, name, askingPrice, quantity, notes, isSold, createdAt, updatedAt
        FROM ItemToSell
        WHERE id IN (\(placeholders));
        """
        return try fetchItems(sql: sql, parameters: ids.map { .text($0.uuidString) })
    }

    func insertSellItem(_ item: SellItem) throws {
        try openIfNeeded()
        let sql = """
        INSERT INTO ItemToSell (id, name, askingPrice, quantity, notes, isSold, createdAt, updatedAt)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?);
        """
        try execute(sql: sql) { [self] statement in
            bind(item, in: statement)
        }
    }

    func insertSellItemAndQueueCreate(_ item: SellItem) throws {
        try openIfNeeded()
        try beginTransaction()
        do {
            try insertSellItem(item)
            try queuePendingOperation(type: .create, item: item, queueID: UUID())
            try commitTransaction()
        } catch {
            try? rollbackTransaction()
            throw error
        }
    }

    func updateSellItem(_ item: SellItem) throws {
        try openIfNeeded()
        let sql = """
        UPDATE ItemToSell
        SET name = ?, askingPrice = ?, quantity = ?, notes = ?, isSold = ?, createdAt = ?, updatedAt = ?
        WHERE id = ?;
        """
        try execute(sql: sql) { [self] statement in
            bind(item.name, to: 1, in: statement)
            bind(NSDecimalNumber(decimal: item.askingPrice).stringValue, to: 2, in: statement)
            sqlite3_bind_int64(statement, 3, Int64(item.quantity))
            bind(item.notes, to: 4, in: statement)
            sqlite3_bind_int(statement, 5, item.isSold ? 1 : 0)
            bind(isoFormatter.string(from: item.createdAt), to: 6, in: statement)
            bind(isoFormatter.string(from: item.updatedAt), to: 7, in: statement)
            bind(item.id.uuidString, to: 8, in: statement)
        }
    }

    func updateSellItemAndQueue(_ item: SellItem, type: PendingSellSyncOperation.OperationType) throws {
        try openIfNeeded()
        try beginTransaction()
        do {
            try updateSellItem(item)
            try queuePendingOperation(type: type, item: item, queueID: UUID())
            try commitTransaction()
        } catch {
            try? rollbackTransaction()
            throw error
        }
    }

    func upsertSellItems(_ items: [SellItem]) throws {
        guard !items.isEmpty else { return }
        try openIfNeeded()
        try execute(sql: "BEGIN IMMEDIATE TRANSACTION;")
        do {
            let sql = """
            INSERT INTO ItemToSell (id, name, askingPrice, quantity, notes, isSold, createdAt, updatedAt)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                name = excluded.name,
                askingPrice = excluded.askingPrice,
                quantity = excluded.quantity,
                notes = excluded.notes,
                isSold = excluded.isSold,
                createdAt = excluded.createdAt,
                updatedAt = excluded.updatedAt;
            """
            for item in items {
                try execute(sql: sql) { [self] statement in
                    bind(item, in: statement)
                }
            }
            try execute(sql: "COMMIT;")
        } catch {
            try? execute(sql: "ROLLBACK;")
            throw error
        }
    }

    func deleteSellItems(ids: [UUID]) throws {
        guard !ids.isEmpty else { return }
        try openIfNeeded()
        let placeholders = Array(repeating: "?", count: ids.count).joined(separator: ", ")
        let sql = "DELETE FROM ItemToSell WHERE id IN (\(placeholders));"
        try execute(sql: sql) { [self] statement in
            for (index, id) in ids.enumerated() {
                bind(id.uuidString, to: Int32(index + 1), in: statement)
            }
        }
    }

    func deleteSellItemsAndQueue(_ items: [SellItem]) throws {
        guard !items.isEmpty else { return }
        try openIfNeeded()
        try beginTransaction()
        do {
            try deleteSellItems(ids: items.map(\.id))
            for item in items {
                try queuePendingOperation(type: .delete, item: item, queueID: UUID())
            }
            try commitTransaction()
        } catch {
            try? rollbackTransaction()
            throw error
        }
    }

    func markItemSold(_ itemID: UUID) throws {
        guard let existing = try fetchSellItem(id: itemID) else { return }
        let updated = SellItem(
            id: existing.id,
            name: existing.name,
            askingPrice: existing.askingPrice,
            quantity: existing.quantity,
            notes: existing.notes,
            isSold: true,
            createdAt: existing.createdAt,
            updatedAt: .now
        )
        try updateSellItemAndQueue(updated, type: .markSold)
    }

    func queuePendingSale(for item: SellItem) throws {
        try queuePendingOperation(type: .markSold, item: item, queueID: item.id)
    }

    func queuePendingOperation(type: PendingSellSyncOperation.OperationType, item: SellItem, queueID: UUID) throws {
        try openIfNeeded()
        let sql = """
        INSERT OR REPLACE INTO \(Self.pendingSyncTable) (id, itemID, itemName, operationType, payload, queuedAt, retryCount)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        let payload = try encode(item)
        try execute(sql: sql) { [self] statement in
            bind(queueID.uuidString, to: 1, in: statement)
            bind(item.id.uuidString, to: 2, in: statement)
            bind(item.name, to: 3, in: statement)
            bind(type.rawValue, to: 4, in: statement)
            bind(payload, to: 5, in: statement)
            bind(isoFormatter.string(from: .now), to: 6, in: statement)
            sqlite3_bind_int64(statement, 7, 0)
        }
    }

    func fetchPendingOperations() throws -> [PendingSellSyncOperation] {
        try openIfNeeded()
        let sql = """
        SELECT id, itemID, operationType, payload, queuedAt, retryCount
        FROM \(Self.pendingSyncTable)
        ORDER BY queuedAt DESC;
        """
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw lastError()
        }

        var operations: [PendingSellSyncOperation] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let idText = sqlite3_column_text(statement, 0),
                let itemIDText = sqlite3_column_text(statement, 1),
                let operationText = sqlite3_column_text(statement, 2),
                let queuedAtText = sqlite3_column_text(statement, 4),
                let id = UUID(uuidString: String(cString: idText)),
                let itemID = UUID(uuidString: String(cString: itemIDText)),
                let type = PendingSellSyncOperation.OperationType(rawValue: String(cString: operationText)),
                let queuedAt = isoFormatter.date(from: String(cString: queuedAtText))
            else {
                continue
            }

            let payload = sqlite3_column_text(statement, 3).flatMap { pointer in
                try? decodeSellItem(json: String(cString: pointer))
            }

            operations.append(
                PendingSellSyncOperation(
                    id: id,
                    itemID: itemID,
                    type: type,
                    payload: payload,
                    queuedAt: queuedAt,
                    retryCount: Int(sqlite3_column_int64(statement, 5))
                )
            )
        }

        return operations
    }

    func fetchPendingSales() throws -> [PendingSale] {
        try openIfNeeded()
        let sql = """
        SELECT id, itemID, itemName, queuedAt
        FROM \(Self.pendingSyncTable)
        ORDER BY queuedAt DESC;
        """
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw lastError()
        }

        var items: [PendingSale] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let idText = sqlite3_column_text(statement, 0),
                let itemIDText = sqlite3_column_text(statement, 1),
                let nameText = sqlite3_column_text(statement, 2),
                let queuedAtText = sqlite3_column_text(statement, 3),
                let id = UUID(uuidString: String(cString: idText)),
                let itemID = UUID(uuidString: String(cString: itemIDText)),
                let queuedAt = isoFormatter.date(from: String(cString: queuedAtText))
            else {
                continue
            }

            items.append(
                PendingSale(
                    id: id,
                    itemID: itemID,
                    itemName: String(cString: nameText),
                    queuedAt: queuedAt
                )
            )
        }

        return items
    }

    func clearPendingSales(ids: [UUID]) throws {
        guard !ids.isEmpty else { return }
        try openIfNeeded()
        let placeholders = Array(repeating: "?", count: ids.count).joined(separator: ", ")
        let sql = "DELETE FROM \(Self.pendingSyncTable) WHERE id IN (\(placeholders));"
        try execute(sql: sql) { [self] statement in
            for (index, id) in ids.enumerated() {
                bind(id.uuidString, to: Int32(index + 1), in: statement)
            }
        }
    }

    func totalSellCount() throws -> Int {
        try count(table: "ItemToSell")
    }

    func totalPendingCount() throws -> Int {
        try count(table: Self.pendingSyncTable)
    }

    private func openIfNeeded() throws {
        if db != nil { return }

        if sqlite3_open(databaseURL.path, &db) != SQLITE_OK {
            throw lastError()
        }

        try createTables()
        try migrateTablesIfNeeded()
        try createIndexes()
    }

    private func createTables() throws {
        let createItemToSell = """
        CREATE TABLE IF NOT EXISTS ItemToSell (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL CHECK(length(trim(name)) > 0),
            askingPrice TEXT NOT NULL,
            quantity INTEGER NOT NULL CHECK(quantity > 0),
            notes TEXT NOT NULL,
            isSold INTEGER NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL,
            CHECK(CAST(askingPrice AS REAL) > 0)
        );
        """

        let createPendingSale = """
        CREATE TABLE IF NOT EXISTS \(Self.pendingSyncTable) (
            id TEXT PRIMARY KEY,
            itemID TEXT NOT NULL,
            itemName TEXT NOT NULL,
            operationType TEXT NOT NULL DEFAULT 'markSold',
            payload TEXT,
            queuedAt TEXT NOT NULL,
            retryCount INTEGER NOT NULL DEFAULT 0
        );
        """

        try execute(sql: createItemToSell)
        try execute(sql: createPendingSale)
    }

    private func migrateTablesIfNeeded() throws {
        let columns = try columnNames(in: "ItemToSell")
        if !columns.contains("createdAt") {
            let fallbackDate = isoFormatter.string(from: .now)
            try execute(sql: "ALTER TABLE ItemToSell ADD COLUMN createdAt TEXT NOT NULL DEFAULT '\(fallbackDate)';")
            try execute(sql: "UPDATE ItemToSell SET createdAt = updatedAt WHERE createdAt = '\(fallbackDate)';")
        }

        let pendingColumns = try columnNames(in: Self.pendingSyncTable)
        if !pendingColumns.contains("operationType") {
            try execute(sql: "ALTER TABLE \(Self.pendingSyncTable) ADD COLUMN operationType TEXT NOT NULL DEFAULT 'markSold';")
        }
        if !pendingColumns.contains("payload") {
            try execute(sql: "ALTER TABLE \(Self.pendingSyncTable) ADD COLUMN payload TEXT;")
        }
        if !pendingColumns.contains("retryCount") {
            try execute(sql: "ALTER TABLE \(Self.pendingSyncTable) ADD COLUMN retryCount INTEGER NOT NULL DEFAULT 0;")
        }
        try backfillPendingOperationPayloadsIfNeeded()
    }

    private func createIndexes() throws {
        try execute(sql: "CREATE INDEX IF NOT EXISTS idx_item_to_sell_updated_at ON ItemToSell(updatedAt DESC);")
        try execute(sql: "CREATE INDEX IF NOT EXISTS idx_item_to_sell_sold_updated_at ON ItemToSell(isSold, updatedAt DESC);")
    }

    private func columnNames(in table: String) throws -> Set<String> {
        let sql = "PRAGMA table_info(\(table));"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw lastError()
        }

        var columns = Set<String>()
        while sqlite3_step(statement) == SQLITE_ROW {
            if let nameText = sqlite3_column_text(statement, 1) {
                columns.insert(String(cString: nameText))
            }
        }
        return columns
    }

    private func count(table: String) throws -> Int {
        try openIfNeeded()
        let sql = "SELECT COUNT(*) FROM \(table);"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw lastError()
        }
        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw lastError()
        }
        return Int(sqlite3_column_int(statement, 0))
    }

    private func countSellItems(whereClause: String, parameters: [SQLiteValue]) throws -> Int {
        let sql = "SELECT COUNT(*) FROM ItemToSell \(whereClause);"
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw lastError()
        }
        try bind(parameters, in: statement)
        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw lastError()
        }
        return Int(sqlite3_column_int(statement, 0))
    }

    private func fetchItems(sql: String, parameters: [SQLiteValue]) throws -> [SellItem] {
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw lastError()
        }
        try bind(parameters, in: statement)

        var items: [SellItem] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let idText = sqlite3_column_text(statement, 0),
                let nameText = sqlite3_column_text(statement, 1),
                let priceText = sqlite3_column_text(statement, 2),
                let notesText = sqlite3_column_text(statement, 4),
                let createdAtText = sqlite3_column_text(statement, 6),
                let updatedAtText = sqlite3_column_text(statement, 7),
                let id = UUID(uuidString: String(cString: idText)),
                let createdAt = isoFormatter.date(from: String(cString: createdAtText)),
                let updatedAt = isoFormatter.date(from: String(cString: updatedAtText))
            else {
                continue
            }

            items.append(
                SellItem(
                    id: id,
                    name: String(cString: nameText),
                    askingPrice: Decimal(string: String(cString: priceText)) ?? 0,
                    quantity: Int(sqlite3_column_int64(statement, 3)),
                    notes: String(cString: notesText),
                    isSold: sqlite3_column_int(statement, 5) == 1,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
            )
        }
        return items
    }

    private func buildWhereClause(for query: SellItemsQuery) -> (sql: String, parameters: [SQLiteValue]) {
        var clauses: [String] = []
        var parameters: [SQLiteValue] = []

        switch query.status {
        case .all:
            break
        case .available:
            clauses.append("isSold = 0")
        case .sold:
            clauses.append("isSold = 1")
        }

        let trimmedSearch = query.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearch.isEmpty {
            clauses.append("(name LIKE ? COLLATE NOCASE OR notes LIKE ? COLLATE NOCASE)")
            let pattern = "%\(trimmedSearch)%"
            parameters.append(.text(pattern))
            parameters.append(.text(pattern))
        }

        guard !clauses.isEmpty else { return ("", parameters) }
        return ("WHERE " + clauses.joined(separator: " AND "), parameters)
    }

    private func buildOrderClause(for query: SellItemsQuery) -> String {
        switch query.sort {
        case .updatedAtDescending:
            return "ORDER BY updatedAt DESC"
        }
    }

    private func beginTransaction() throws {
        try execute(sql: "BEGIN IMMEDIATE TRANSACTION;")
    }

    private func commitTransaction() throws {
        try execute(sql: "COMMIT;")
    }

    private func rollbackTransaction() throws {
        try execute(sql: "ROLLBACK;")
    }

    private func backfillPendingOperationPayloadsIfNeeded() throws {
        let sql = """
        SELECT id, itemID
        FROM \(Self.pendingSyncTable)
        WHERE payload IS NULL;
        """
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw lastError()
        }

        var missingPayloads: [(queueID: UUID, itemID: UUID)] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let idText = sqlite3_column_text(statement, 0),
                let itemIDText = sqlite3_column_text(statement, 1),
                let queueID = UUID(uuidString: String(cString: idText)),
                let itemID = UUID(uuidString: String(cString: itemIDText))
            else {
                continue
            }
            missingPayloads.append((queueID, itemID))
        }

        guard !missingPayloads.isEmpty else { return }

        for entry in missingPayloads {
            guard let item = try fetchSellItem(id: entry.itemID) else { continue }
            try updatePendingPayload(queueID: entry.queueID, item: item)
        }
    }

    private func updatePendingPayload(queueID: UUID, item: SellItem) throws {
        let sql = """
        UPDATE \(Self.pendingSyncTable)
        SET payload = ?
        WHERE id = ?;
        """
        let payload = try encode(item)
        try execute(sql: sql) { [self] statement in
            bind(payload, to: 1, in: statement)
            bind(queueID.uuidString, to: 2, in: statement)
        }
    }

    private func encode(_ item: SellItem) throws -> String {
        let payload: [String: Any] = [
            "id": item.id.uuidString,
            "name": item.name,
            "askingPrice": NSDecimalNumber(decimal: item.askingPrice).stringValue,
            "quantity": item.quantity,
            "notes": item.notes,
            "isSold": item.isSold,
            "createdAt": isoFormatter.string(from: item.createdAt),
            "updatedAt": isoFormatter.string(from: item.updatedAt)
        ]
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        guard let json = String(data: data, encoding: .utf8) else {
            throw AppError.persistence("Could not encode queued sell item payload.")
        }
        return json
    }

    private func decodeSellItem(json: String) throws -> SellItem {
        let data = Data(json.utf8)
        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let idText = object["id"] as? String,
            let id = UUID(uuidString: idText),
            let name = object["name"] as? String,
            let priceText = object["askingPrice"] as? String,
            let quantity = object["quantity"] as? Int,
            let notes = object["notes"] as? String,
            let isSold = object["isSold"] as? Bool,
            let createdAtText = object["createdAt"] as? String,
            let updatedAtText = object["updatedAt"] as? String,
            let createdAt = isoFormatter.date(from: createdAtText),
            let updatedAt = isoFormatter.date(from: updatedAtText)
        else {
            throw AppError.persistence("Could not decode queued sell item payload.")
        }

        return SellItem(
            id: id,
            name: name,
            askingPrice: Decimal(string: priceText) ?? 0,
            quantity: quantity,
            notes: notes,
            isSold: isSold,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private func execute(sql: String, binder: ((OpaquePointer?) throws -> Void)? = nil) throws {
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw lastError()
        }
        try binder?(statement)
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw lastError()
        }
    }

    private func bind(_ item: SellItem, in statement: OpaquePointer?) {
        bind(item.id.uuidString, to: 1, in: statement)
        bind(item.name, to: 2, in: statement)
        bind(NSDecimalNumber(decimal: item.askingPrice).stringValue, to: 3, in: statement)
        sqlite3_bind_int64(statement, 4, Int64(item.quantity))
        bind(item.notes, to: 5, in: statement)
        sqlite3_bind_int(statement, 6, item.isSold ? 1 : 0)
        bind(isoFormatter.string(from: item.createdAt), to: 7, in: statement)
        bind(isoFormatter.string(from: item.updatedAt), to: 8, in: statement)
    }

    private func bind(_ parameters: [SQLiteValue], in statement: OpaquePointer?) throws {
        for (index, parameter) in parameters.enumerated() {
            switch parameter {
            case let .text(value):
                bind(value, to: Int32(index + 1), in: statement)
            case let .int(value):
                sqlite3_bind_int64(statement, Int32(index + 1), Int64(value))
            }
        }
    }

    private func bind(_ value: String, to index: Int32, in statement: OpaquePointer?) {
        sqlite3_bind_text(statement, index, value, -1, transientSQLiteDestructor)
    }

    private func lastError() -> AppError {
        let message = db.flatMap { sqlite3_errmsg($0) }.map { String(cString: $0) } ?? "Unknown SQLite error"
        return .persistence(message)
    }
}

private enum SQLiteValue {
    case text(String)
    case int(Int)
}

nonisolated(unsafe) private let transientSQLiteDestructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
