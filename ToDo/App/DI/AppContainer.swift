import Foundation
import SwiftData

@MainActor
final class AppContainer {
    struct BuyDependencies {
        let loadCatalog: LoadBuyCatalogUseCase
        let loadWishlist: LoadWishlistUseCase
        let setWishlistQuantity: SetWishlistQuantityUseCase
    }

    struct SellDependencies {
        let inventoryReader: SellInventoryReader
        let inventoryWriter: SellInventoryWriter
        let createItem: CreateSellItemUseCase
        let updateItem: UpdateSellItemUseCase
        let sellAmount: SellAmountUseCase
    }

    private struct BuyStack {
        let catalogRepository: BuyRepository
        let wishlistLocalDataSource: WishlistLocalDataSource
        let wishlistRemoteDataSource: WishlistRemoteDataSource
        let wishlistRepository: WishlistRepository
    }

    private struct SellStack {
        let localDataSource: SellLocalDataSource
        let syncLocalDataSource: SyncLocalDataSource
        let remoteGateway: SellRemoteGateway
        let repository: SellRepository
        let syncRepository: SyncRepository
        let syncOrchestrator: SyncOrchestrator
        let backgroundTaskManager: SellSyncBackgroundTaskManager
    }

    let connectivityMonitor: ConnectivityMonitoring
    let inventoryServer: MockInventoryServer
    let toCallServer: MockToCallServer
    let buyCatalogRepository: BuyRepository
    let toCallRepository: CallRepository
    let buyWishlistLocalDataSource: WishlistLocalDataSource
    let buyWishlistRemoteDataSource: WishlistRemoteDataSource
    let sellLocalDataSource: SellLocalDataSource
    let syncLocalDataSource: SyncLocalDataSource
    let sellRemoteGateway: SellRemoteGateway
    let sellRepository: SellRepository
    let syncRepository: SyncRepository
    let buyWishlistRepository: WishlistRepository
    let syncOrchestrator: SyncOrchestrator
    let sellSyncBackgroundTaskManager: SellSyncBackgroundTaskManager

    init(modelContainer: ModelContainer) {
        connectivityMonitor = NetworkConnectivityMonitor()
        inventoryServer = MockInventoryServer()
        toCallServer = MockToCallServer()

        let sellStack = Self.makeSellStack(
            connectivityMonitor: connectivityMonitor,
            inventoryServer: inventoryServer
        )
        sellLocalDataSource = sellStack.localDataSource
        syncLocalDataSource = sellStack.syncLocalDataSource
        sellRemoteGateway = sellStack.remoteGateway
        sellRepository = sellStack.repository
        syncRepository = sellStack.syncRepository
        syncOrchestrator = sellStack.syncOrchestrator
        sellSyncBackgroundTaskManager = sellStack.backgroundTaskManager

        let buyStack = Self.makeBuyStack(
            modelContainer: modelContainer,
            inventoryServer: inventoryServer
        )
        buyCatalogRepository = buyStack.catalogRepository
        buyWishlistLocalDataSource = buyStack.wishlistLocalDataSource
        buyWishlistRemoteDataSource = buyStack.wishlistRemoteDataSource
        buyWishlistRepository = buyStack.wishlistRepository

        toCallRepository = CallRepositoryImp(server: toCallServer)
    }

    var buyDependencies: BuyDependencies {
        BuyDependencies(
            loadCatalog: LoadBuyCatalogUseCase(
                buyRepository: buyCatalogRepository,
                wishlistRepository: buyWishlistRepository
            ),
            loadWishlist: LoadWishlistUseCase(repository: buyWishlistRepository),
            setWishlistQuantity: SetWishlistQuantityUseCase(repository: buyWishlistRepository)
        )
    }

    var sellDependencies: SellDependencies {
        SellDependencies(
            inventoryReader: sellRepository,
            inventoryWriter: sellRepository,
            createItem: CreateSellItemUseCase(repository: sellRepository),
            updateItem: UpdateSellItemUseCase(repository: sellRepository),
            sellAmount: SellAmountUseCase(repository: sellRepository)
        )
    }
}

private extension AppContainer {
    private static func makeBuyStack(
        modelContainer: ModelContainer,
        inventoryServer: MockInventoryServer
    ) -> BuyStack {
        let catalogRepository = RemoteBuyRepositoryImp(server: inventoryServer)
        let wishlistLocalDataSource = SwiftDataWishlistLocalDataSource(modelContainer: modelContainer)
        let wishlistRemoteDataSource = MockWishlistRemoteDataSource(server: inventoryServer)
        let wishlistRepository = WishlistRepositoryImp(
            localDataSource: wishlistLocalDataSource,
            remoteDataSource: wishlistRemoteDataSource
        )

        return BuyStack(
            catalogRepository: catalogRepository,
            wishlistLocalDataSource: wishlistLocalDataSource,
            wishlistRemoteDataSource: wishlistRemoteDataSource,
            wishlistRepository: wishlistRepository
        )
    }

    private static func makeSellStack(
        connectivityMonitor: ConnectivityMonitoring,
        inventoryServer: MockInventoryServer
    ) -> SellStack {
        let sqliteStore = SQLiteSellStore()
        let localDataSource = SQLiteSellLocalDataSource(store: sqliteStore)
        let syncLocalDataSource = SQLiteSyncLocalDataSource(store: sqliteStore)
        let remoteGateway = MockSellRemoteGateway(server: inventoryServer)
        let repository: SellRepository = localDataSource
        let syncRepository = SyncRepositoryImp(
            localDataSource: syncLocalDataSource,
            remoteDataSource: remoteGateway
        )
        let syncOrchestrator = SyncOrchestrator(
            syncRepository: syncRepository,
            connectivityMonitor: connectivityMonitor
        )
        let backgroundTaskManager = SellSyncBackgroundTaskManager(
            syncOrchestrator: syncOrchestrator
        )

        return SellStack(
            localDataSource: localDataSource,
            syncLocalDataSource: syncLocalDataSource,
            remoteGateway: remoteGateway,
            repository: repository,
            syncRepository: syncRepository,
            syncOrchestrator: syncOrchestrator,
            backgroundTaskManager: backgroundTaskManager
        )
    }
}
