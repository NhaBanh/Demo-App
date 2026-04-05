import Foundation
import SQLite3

struct SQLitePendingSyncStore {
    let tableName: String

    nonisolated init(tableName: String) {
        self.tableName = tableName
    }

    func queuePendingOperation(
        type: QueuedSellOperation.OperationType,
        item: SellItem,
        queueID: UUID,
        database: SQLiteDatabase
    ) throws {
        let sql = """
        INSERT OR REPLACE INTO \(tableName) (id, itemID, itemName, operationType, payload, queuedAt, retryCount)
        VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        let payload = try encode(item)
        try database.execute(sql: sql) { statement in
            database.bind(queueID.uuidString, to: 1, in: statement)
            database.bind(item.id.uuidString, to: 2, in: statement)
            database.bind(item.title, to: 3, in: statement)
            database.bind(type.rawValue, to: 4, in: statement)
            database.bind(payload, to: 5, in: statement)
            database.bind(database.dateString(from: .now), to: 6, in: statement)
            sqlite3_bind_int64(statement, 7, 0)
        }
    }

    func fetchPendingOperations(database: SQLiteDatabase) throws -> [QueuedSellOperation] {
        let sql = """
        SELECT id, itemID, operationType, payload, queuedAt, retryCount
        FROM \(tableName)
        ORDER BY queuedAt DESC;
        """
        var statement: OpaquePointer?
        statement = try database.prepare(sql: sql)
        defer { sqlite3_finalize(statement) }

        var operations: [QueuedSellOperation] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let idText = sqlite3_column_text(statement, 0),
                let itemIDText = sqlite3_column_text(statement, 1),
                let operationText = sqlite3_column_text(statement, 2),
                let queuedAtText = sqlite3_column_text(statement, 4),
                let id = UUID(uuidString: String(cString: idText)),
                let itemID = UUID(uuidString: String(cString: itemIDText)),
                let type = QueuedSellOperation.OperationType(databaseValue: String(cString: operationText)),
                let queuedAt = database.parseDate(String(cString: queuedAtText))
            else {
                continue
            }

            let payload = sqlite3_column_text(statement, 3).flatMap { pointer in
                try? decodeSellItem(json: String(cString: pointer))
            }
            let retryCount = Int(sqlite3_column_int64(statement, 5))

            operations.append(
                QueuedSellOperation(
                    id: id,
                    itemID: itemID,
                    type: type,
                    payload: payload,
                    queuedAt: queuedAt,
                    retryCount: retryCount
                )
            )
        }

        return operations
    }

    func clearPendingSales(ids: [UUID], database: SQLiteDatabase) throws {
        guard !ids.isEmpty else { return }
        let placeholders = Array(repeating: "?", count: ids.count).joined(separator: ", ")
        let sql = "DELETE FROM \(tableName) WHERE id IN (\(placeholders));"
        try database.execute(sql: sql) { statement in
            for (index, id) in ids.enumerated() {
                database.bind(id.uuidString, to: Int32(index + 1), in: statement)
            }
        }
    }

    func totalPendingCount(database: SQLiteDatabase) throws -> Int {
        try database.count(table: tableName)
    }

    func backfillLegacyPendingPayloads(database: SQLiteDatabase) throws {
        let sql = """
        SELECT id, itemID, itemName, queuedAt
        FROM \(tableName)
        WHERE payload IS NULL;
        """
        var statement: OpaquePointer?
        statement = try database.prepare(sql: sql)
        defer { sqlite3_finalize(statement) }

        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let queueIDText = sqlite3_column_text(statement, 0),
                let itemIDText = sqlite3_column_text(statement, 1),
                let nameText = sqlite3_column_text(statement, 2),
                let queuedAtText = sqlite3_column_text(statement, 3),
                let queueID = UUID(uuidString: String(cString: queueIDText)),
                let itemID = UUID(uuidString: String(cString: itemIDText)),
                let timestamp = database.parseDate(String(cString: queuedAtText))
            else {
                continue
            }

            let legacyItem = SellItem(
                id: itemID,
                title: String(cString: nameText),
                askingPrice: 1,
                quantity: 1,
                detail: "",
                status: .active,
                createdAt: timestamp,
                updatedAt: timestamp
            )

            try queuePendingOperation(type: .update, item: legacyItem, queueID: queueID, database: database)
        }
    }

    private func encode(_ item: SellItem) throws -> String {
        let data = try JSONEncoder().encode(item)
        guard let json = String(data: data, encoding: .utf8) else {
            throw AppError.persistence("Unable to encode queued sell item payload.")
        }
        return json
    }

    private func decodeSellItem(json: String) throws -> SellItem {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(SellItem.self, from: data)
    }
}
