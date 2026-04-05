import Foundation
import SQLite3

final class SQLiteDatabase {
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private let legacyISOFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    private let databaseURL: URL
    private var db: OpaquePointer?

    nonisolated init(filename: String) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        databaseURL = documentsURL.appendingPathComponent(filename)
    }

    deinit {
        sqlite3_close(db)
    }

    var isOpen: Bool {
        db != nil
    }

    func open() throws {
        guard db == nil else { return }

        if sqlite3_open(databaseURL.path, &db) != SQLITE_OK {
            throw lastError()
        }
    }

    func execute(sql: String, binder: ((OpaquePointer?) throws -> Void)? = nil) throws {
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

    func inTransaction(_ operation: () throws -> Void) throws {
        try execute(sql: "BEGIN IMMEDIATE TRANSACTION;")
        do {
            try operation()
            try execute(sql: "COMMIT;")
        } catch {
            try? execute(sql: "ROLLBACK;")
            throw error
        }
    }

    func columnNames(in table: String) throws -> Set<String> {
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

    func count(table: String) throws -> Int {
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

    func count(sql: String, parameters: [SQLiteValue]) throws -> Int {
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

    func prepare(sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw lastError()
        }
        return statement
    }

    func bind(_ parameters: [SQLiteValue], in statement: OpaquePointer?) throws {
        for (index, parameter) in parameters.enumerated() {
            switch parameter {
            case let .text(value):
                bind(value, to: Int32(index + 1), in: statement)
            case let .int(value):
                sqlite3_bind_int64(statement, Int32(index + 1), Int64(value))
            }
        }
    }

    func bind(_ value: String, to index: Int32, in statement: OpaquePointer?) {
        sqlite3_bind_text(statement, index, value, -1, transientSQLiteDestructor)
    }

    func bind(_ item: SellItem, in statement: OpaquePointer?) {
        bind(item.id.uuidString, to: 1, in: statement)
        bind(item.title, to: 2, in: statement)
        bind(NSDecimalNumber(decimal: item.askingPrice).stringValue, to: 3, in: statement)
        sqlite3_bind_int64(statement, 4, Int64(item.quantity))
        bind(item.detail, to: 5, in: statement)
        bind(item.status.rawValue, to: 6, in: statement)
        sqlite3_bind_int(statement, 7, item.quantity == 0 ? 1 : 0)
        bind(isoFormatter.string(from: item.createdAt), to: 8, in: statement)
        bind(isoFormatter.string(from: item.updatedAt), to: 9, in: statement)
    }

    func dateString(from date: Date) -> String {
        isoFormatter.string(from: date)
    }

    func parseDate(_ value: String) -> Date? {
        isoFormatter.date(from: value) ?? legacyISOFormatter.date(from: value)
    }

    func lastError() -> AppError {
        let message = db.flatMap { sqlite3_errmsg($0) }.map { String(cString: $0) } ?? "Unknown SQLite error"
        return .persistence(message)
    }
}

enum SQLiteValue {
    case text(String)
    case int(Int)
}

nonisolated(unsafe) private let transientSQLiteDestructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
