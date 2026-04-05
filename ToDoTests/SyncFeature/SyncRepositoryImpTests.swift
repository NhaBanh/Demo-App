import XCTest
@testable import ToDo

final class SyncRepositoryImpTests: XCTestCase {
    func testSyncPendingChangesRemovesSyncedCreateOperationAndUpdatesRemoteInventory() async throws {
        let filename = TestStoreHelpers.makeSQLiteFilename(prefix: "sync-create")
        defer { TestStoreHelpers.removeSQLiteFile(named: filename) }

        let store = SQLiteSellStore(filename: filename)
        let sellLocalDataSource = SQLiteSellLocalDataSource(store: store)
        let localDataSource: SyncLocalDataSource = SQLiteSyncLocalDataSource(store: store)
        let remoteServer = MockInventoryServer(inventoryItems: [])
        let remoteDataSource: SellRemoteGateway = MockSellRemoteGateway(server: remoteServer)
        let repository = SyncRepositoryImp(localDataSource: localDataSource, remoteDataSource: remoteDataSource)

        let created = try await sellLocalDataSource.create(
            .fixture(title: "Desk Lamp", askingPrice: 45, quantity: 3, detail: "Warm light")
        )

        let syncedOperations = try await repository.syncPendingChanges()
        let pending = try await localDataSource.pendingSyncOperations()
        let remoteItems = try await remoteServer.fetchSellItems()

        XCTAssertEqual(syncedOperations.count, 1)
        XCTAssertEqual(syncedOperations.first?.type, .create)
        XCTAssertTrue(pending.isEmpty)
        XCTAssertEqual(remoteItems.map(\.id), [created.id])
        XCTAssertEqual(remoteItems.first?.title, "Desk Lamp")
        XCTAssertEqual(remoteItems.first?.quantity, 3)
    }

    func testSyncPendingChangesReplaysUpdateAndClearsQueue() async throws {
        let filename = TestStoreHelpers.makeSQLiteFilename(prefix: "sync-update")
        defer { TestStoreHelpers.removeSQLiteFile(named: filename) }

        let existingID = UUID()
        let now = Date.now
        let remoteServer = MockInventoryServer(
            inventoryItems: [
                RemoteInventoryItemDTO(
                    id: existingID,
                    title: "Barcode Scanner",
                    detail: "Compact scanner",
                    price: 89,
                    category: .hardware,
                    availability: .available,
                    quantity: 2,
                    status: .active,
                    createdAt: now,
                    updatedAt: now
                )
            ]
        )

        let store = SQLiteSellStore(filename: filename)
        let localDataSource: SyncLocalDataSource = SQLiteSyncLocalDataSource(store: store)
        let remoteDataSource: SellRemoteGateway = MockSellRemoteGateway(server: remoteServer)
        let repository = SyncRepositoryImp(localDataSource: localDataSource, remoteDataSource: remoteDataSource)

        let updatedItem = SellItem(
            id: existingID,
            title: "Barcode Scanner",
            askingPrice: 89,
            quantity: 1,
            detail: "Compact scanner",
            status: .active,
            createdAt: now,
            updatedAt: now
        )
        try await store.insertSellItem(updatedItem)
        try await store.queuePendingOperation(type: .update, item: updatedItem, queueID: existingID)

        let syncedOperations = try await repository.syncPendingChanges()
        let pending = try await localDataSource.pendingSyncOperations()
        let remoteItems = try await remoteServer.fetchSellItems()

        XCTAssertEqual(syncedOperations.count, 1)
        XCTAssertEqual(syncedOperations.first?.type, .update)
        XCTAssertTrue(pending.isEmpty)
        XCTAssertEqual(remoteItems.first?.quantity, 1)
    }
}
