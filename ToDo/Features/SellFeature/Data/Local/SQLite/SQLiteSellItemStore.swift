import Foundation
import SQLite3

struct SQLiteSellItemStore {
    nonisolated init() {}

    func fetchSellItems(query: SellItemsQuery, database: SQLiteDatabase) throws -> SellItemsPage {
        let sanitizedPage = max(1, query.page)
        let sanitizedPageSize = max(1, query.pageSize)
        let whereClause = buildWhereClause(for: query)
        let orderClause = buildOrderClause(for: query)
        let offset = (sanitizedPage - 1) * sanitizedPageSize

        let totalCount = try database.count(
            sql: "SELECT COUNT(*) FROM ItemToSell \(whereClause.sql);",
            parameters: whereClause.parameters
        )
        let sql = """
        SELECT id, name, askingPrice, quantity, notes, status, createdAt, updatedAt
        FROM ItemToSell
        \(whereClause.sql)
        \(orderClause)
        LIMIT ? OFFSET ?;
        """

        var parameters = whereClause.parameters
        parameters.append(.int(sanitizedPageSize))
        parameters.append(.int(offset))

        let items = try fetchItems(sql: sql, parameters: parameters, database: database)
        let loadedCount = offset + items.count

        return SellItemsPage(
            items: items,
            page: sanitizedPage,
            pageSize: sanitizedPageSize,
            totalCount: totalCount,
            hasMore: loadedCount < totalCount
        )
    }

    func fetchSellItem(id: UUID, database: SQLiteDatabase) throws -> SellItem? {
        let items = try fetchItems(
            sql: """
            SELECT id, name, askingPrice, quantity, notes, status, createdAt, updatedAt
            FROM ItemToSell
            WHERE id = ?
            LIMIT 1;
            """,
            parameters: [.text(id.uuidString)],
            database: database
        )
        return items.first
    }

    func fetchSellItems(ids: [UUID], database: SQLiteDatabase) throws -> [SellItem] {
        guard !ids.isEmpty else { return [] }
        let placeholders = Array(repeating: "?", count: ids.count).joined(separator: ", ")
        let sql = """
        SELECT id, name, askingPrice, quantity, notes, status, createdAt, updatedAt
        FROM ItemToSell
        WHERE id IN (\(placeholders));
        """
        return try fetchItems(sql: sql, parameters: ids.map { .text($0.uuidString) }, database: database)
    }

    func insertSellItem(_ item: SellItem, database: SQLiteDatabase) throws {
        let sql = """
        INSERT INTO ItemToSell (id, name, askingPrice, quantity, notes, status, isSold, createdAt, updatedAt)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        try database.execute(sql: sql) { statement in
            database.bind(item, in: statement)
        }
    }

    func updateSellItem(_ item: SellItem, database: SQLiteDatabase) throws {
        let sql = """
        UPDATE ItemToSell
        SET name = ?, askingPrice = ?, quantity = ?, notes = ?, status = ?, isSold = ?, createdAt = ?, updatedAt = ?
        WHERE id = ?;
        """
        try database.execute(sql: sql) { statement in
            database.bind(item.title, to: 1, in: statement)
            database.bind(NSDecimalNumber(decimal: item.askingPrice).stringValue, to: 2, in: statement)
            sqlite3_bind_int64(statement, 3, Int64(item.quantity))
            database.bind(item.detail, to: 4, in: statement)
            database.bind(item.status.rawValue, to: 5, in: statement)
            sqlite3_bind_int(statement, 6, item.quantity == 0 ? 1 : 0)
            database.bind(database.dateString(from: item.createdAt), to: 7, in: statement)
            database.bind(database.dateString(from: item.updatedAt), to: 8, in: statement)
            database.bind(item.id.uuidString, to: 9, in: statement)
        }
    }

    func upsertSellItems(_ items: [SellItem], database: SQLiteDatabase) throws {
        guard !items.isEmpty else { return }
        try database.inTransaction {
            let sql = """
            INSERT INTO ItemToSell (id, name, askingPrice, quantity, notes, status, isSold, createdAt, updatedAt)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                name = excluded.name,
                askingPrice = excluded.askingPrice,
                quantity = excluded.quantity,
                notes = excluded.notes,
                status = excluded.status,
                isSold = excluded.isSold,
                createdAt = excluded.createdAt,
                updatedAt = excluded.updatedAt;
            """
            for item in items {
                try database.execute(sql: sql) { statement in
                    database.bind(item, in: statement)
                }
            }
        }
    }

    func deleteSellItems(ids: [UUID], database: SQLiteDatabase) throws {
        guard !ids.isEmpty else { return }
        let placeholders = Array(repeating: "?", count: ids.count).joined(separator: ", ")
        let sql = "DELETE FROM ItemToSell WHERE id IN (\(placeholders));"
        try database.execute(sql: sql) { statement in
            for (index, id) in ids.enumerated() {
                database.bind(id.uuidString, to: Int32(index + 1), in: statement)
            }
        }
    }

    func totalSellCount(database: SQLiteDatabase) throws -> Int {
        try database.count(table: "ItemToSell")
    }

    private func fetchItems(
        sql: String,
        parameters: [SQLiteValue],
        database: SQLiteDatabase
    ) throws -> [SellItem] {
        var statement: OpaquePointer?
        statement = try database.prepare(sql: sql)
        defer { sqlite3_finalize(statement) }
        try database.bind(parameters, in: statement)

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
                let statusText = sqlite3_column_text(statement, 5),
                let status = SellItemStatus(rawValue: String(cString: statusText)),
                let createdAt = database.parseDate(String(cString: createdAtText)),
                let updatedAt = database.parseDate(String(cString: updatedAtText))
            else {
                continue
            }

            items.append(
                SellItem(
                    id: id,
                    title: String(cString: nameText),
                    askingPrice: Decimal(string: String(cString: priceText)) ?? 0,
                    quantity: Int(sqlite3_column_int64(statement, 3)),
                    detail: String(cString: notesText),
                    status: status,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
            )
        }
        return items
    }

    private func buildWhereClause(for query: SellItemsQuery) -> (sql: String, parameters: [SQLiteValue]) {
        var clauses: [String] = []

        switch query.status {
        case .all:
            break
        case .available:
            clauses.append("quantity > 0 AND status = 'active'")
        case .soldOut:
            clauses.append("quantity = 0 AND status = 'active'")
        }

        guard !clauses.isEmpty else { return ("", []) }
        return ("WHERE " + clauses.joined(separator: " AND "), [])
    }

    private func buildOrderClause(for query: SellItemsQuery) -> String {
        switch query.sort {
        case .updatedAtDescending:
            return "ORDER BY updatedAt DESC"
        }
    }
}
