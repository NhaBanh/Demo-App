import Foundation
import SwiftData

@MainActor
final class AppContainer {
    let connectivityMonitor: ConnectivityMonitoring
    let inventoryServer: MockInventoryServer
    let buyRepository: BuyRepository
    let toCallRepository: ToCallRepository
    let sqliteSellRepository: SQLiteSellRepositoryImp
    let sellSyncQueueRepository: SellSyncQueueRepository
    let sellMutationService: SellMutationService
    let sellRemoteRepository: SellRemoteRepository
    let sellSyncRepository: SellSyncRepository
    let wishlistRepository: WishlistRepository

    init(modelContainer: ModelContainer) {
        connectivityMonitor = NetworkConnectivityMonitor()
        inventoryServer = MockInventoryServer()
        let sqliteStore = SQLiteSellStore()
        sqliteSellRepository = SQLiteSellRepositoryImp(store: sqliteStore)
        sellSyncQueueRepository = SQLiteSellSyncQueueRepositoryImp(store: sqliteStore)
        sellMutationService = SQLiteSellMutationServiceImp(store: sqliteStore)
        sellRemoteRepository = RemoteSellRepositoryImp(server: inventoryServer)
        sellSyncRepository = HybridSellSyncRepositoryImp(
            queueRepository: sellSyncQueueRepository,
            remoteRepository: sellRemoteRepository
        )
        buyRepository = RemoteBuyRepositoryImp(server: inventoryServer)
        toCallRepository = MockToCallRepository()
        wishlistRepository = SwiftDataWishlistRepositoryImp(modelContainer: modelContainer)
    }

    func makeSellRepository() -> ToSellRepository {
        sqliteSellRepository
    }

    func makeSellRemoteRepository() -> SellRemoteRepository {
        sellRemoteRepository
    }

    func makeSellSyncRepository() -> SellSyncRepository {
        sellSyncRepository
    }
}
