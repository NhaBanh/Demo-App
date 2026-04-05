# Project Folder Structure

This document describes the current project structure and the responsibility of each folder.

## Root

```text
.
├── Task.md
├── ToDo
├── ToDoTests
└── ToDo.xcodeproj
```

- `Task.md`: assignment brief and required features.
- `ToDo/`: main application source code.
- `ToDoTests/`: unit tests and shared test doubles.
- `ToDo.xcodeproj/`: Xcode project configuration.

## Application Source Tree

```text
ToDo
├── App
│   ├── DI
│   │   ├── AppContainer+Sync.swift
│   │   ├── AppContainer+Buy.swift
│   │   ├── AppContainer+ToCall.swift
│   │   ├── AppContainer+ToSell.swift
│   │   ├── AppContainer+HomeSummary.swift
│   │   └── AppContainer.swift
│   ├── RootView.swift
│   ├── SellSyncBackgroundTaskManager.swift
│   └── ToDoApp.swift
├── Assets.xcassets
│   ├── AccentColor.colorset
│   ├── AppIcon.appiconset
│   └── Contents.json
├── Features
│   ├── Home
│   │   └── Domain
│   ├── BuyFeature
│   │   ├── Data
│   │   │   ├── BuyRepositoryImp.swift
│   │   │   ├── WishlistLocalDataSource.swift
│   │   │   ├── WishlistRemoteDataSource.swift
│   │   │   ├── WishlistRepositoryImp.swift
│   │   │   ├── WishlistSnapshotRefresher.swift
│   │   │   ├── WishlistSnapshotResolver.swift
│   │   │   ├── Local
│   │   │   │   ├── SwiftDataWishlistLocalDataSource.swift
│   │   │   │   └── WishlistSwiftDataModel.swift
│   │   │   └── Remote
│   │   │       ├── RemoteBuyItemDTO.swift
│   │   │       └── MockWishlistRemoteDataSource.swift
│   │   ├── Domain
│   │   │   ├── Entities
│   │   │   │   ├── BuyItem.swift
│   │   │   │   └── WishlistItemRecord.swift
│   │   │   ├── Models
│   │   │   │   ├── BuyCatalogQuery.swift
│   │   │   │   └── BuyCatalogListItem.swift
│   │   │   ├── Repositories
│   │   │   │   ├── BuyRepository.swift
│   │   │   │   └── WishlistRepository.swift
│   │   │   └── UseCases
│   │   │       ├── LoadWishlistUseCase.swift
│   │   │       ├── LoadBuyCatalogUseCase.swift
│   │   │       └── SetWishlistQuantityUseCase.swift
│   │   └── Presentation
│   │       ├── Components
│   │       │   ├── BuyCatalogItemRow.swift
│   │       │   └── WishlistItemRow.swift
│   │       ├── BuyCatalogDetailView.swift
│   │       ├── BuyCatalogView.swift
│   │       ├── BuyCatalogViewModel.swift
│   │       ├── WishlistView.swift
│   │       └── WishlistViewModel.swift
│   ├── CallFeature
│   │   ├── Data
│   │   │   ├── CallRepositoryImp.swift
│   │   │   └── Remote
│   │   │       ├── MockToCallServer.swift
│   │   │       └── RemotePersonToCallDTO.swift
│   │   ├── Domain
│   │   │   ├── Entities
│   │   │   │   └── PersonToCall.swift
│   │   │   ├── Repositories
│   │   │   │   └── CallRepository.swift
│   │   └── Presentation
│   │       ├── Components
│   │       │   └── CallPersonCard.swift
│   │       ├── CallView.swift
│   │       └── CallViewModel.swift
│   ├── SellFeature
│   │   ├── Data
│   │   │   ├── SellLocalDataSource.swift
│   │   │   ├── Local
│   │   │   │   ├── SQLite
│   │   │   │   │   ├── SQLiteDatabase.swift
│   │   │   │   │   ├── SQLitePendingSyncStore.swift
│   │   │   │   │   ├── SQLiteSchemaManager.swift
│   │   │   │   │   ├── SQLiteSellItemStore.swift
│   │   │   │   │   └── SQLiteSellStore.swift
│   │   │   │   └── SQLiteSellLocalDataSource.swift
│   │   ├── Domain
│   │   │   ├── Entities
│   │   │   │   └── SellItem.swift
│   │   │   ├── Models
│   │   │   │   └── SellInventoryModels.swift
│   │   │   ├── Repositories
│   │   │   │   └── SellRepository.swift
│   │   │   └── UseCases
│   │   │       ├── CreateSellItemUseCase.swift
│   │   │       ├── SellItemValidation.swift
│   │   │       └── UpdateSellItemUseCase.swift
│   │   └── Presentation
│   │       ├── ToSellView.swift
│   │       └── ToSellViewModel.swift
│   └── SyncFeature
│       ├── Application
│       │   └── SyncOrchestrator.swift
│       ├── Data
│       │   ├── SellRemoteGateway.swift
│       │   ├── SyncLocalDataSource.swift
│       │   ├── SyncRepositoryImp.swift
│       │   ├── Local
│       │   │   └── SQLiteSyncLocalDataSource.swift
│       │   └── Remote
│       │       ├── MockSellRemoteGateway.swift
│       │       └── RemoteSellItemDTO.swift
│       ├── Domain
│       │   ├── Entities
│       │   │   └── QueuedSellOperation.swift
│       │   ├── Repositories
│       │   │   └── SyncRepository.swift
│       └── Presentation
│           ├── SyncView.swift
│           └── SyncViewModel.swift
├── Shared
│   ├── AppError.swift
│   ├── AutoRetryCoordinator.swift
│   ├── ConnectivityMonitoring.swift
│   ├── TransientErrorClassifier.swift
│   ├── Infrastructure
│   │   └── Data
│   │       └── Remote
│   │           ├── MockInventoryServer.swift
│   │           └── RemoteInventoryItemDTO.swift
│   └── Presentation
│       ├── BuySummaryBuilder.swift
│       ├── SellSyncSummaryLoader.swift
│       ├── HomeSummary.swift
│       └── HomeSummaryViewModel.swift
```

```text
ToDoTests
├── Architecture
│   └── DomainBoundaryFitnessTests.swift
├── BuyFeature
│   ├── LoadBuyCatalogUseCaseTests.swift
│   ├── LoadWishlistUseCaseTests.swift
│   ├── BuyCatalogViewModelTests.swift
│   ├── SetWishlistQuantityUseCaseTests.swift
│   ├── WishlistViewModelTests.swift
│   └── WishlistRepositoryImpTests.swift
├── CallFeature
│   └── CallViewModelTests.swift
├── SellFeature
│   ├── CreateSellItemUseCaseTests.swift
│   ├── SQLiteSellStoreTests.swift
│   ├── ToSellViewModelTests.swift
│   └── UpdateSellItemUseCaseTests.swift
├── Shared
│   └── TestDoubles
│       ├── RepositoryFakes.swift
│       └── TestStoreHelpers.swift
└── SyncFeature
    ├── SyncRepositoryImpTests.swift
    └── SyncViewModelTests.swift
```

## Folder Responsibilities

### `ToDo/App`

Application bootstrap and dependency wiring.

- `ToDoApp.swift`: app entry point.
- `RootView.swift`: home-first app shell and module navigation shell.
- `SellSyncBackgroundTaskManager.swift`: registers and schedules periodic app-refresh sync work.
- `DI/`: dependency injection container and feature factory/composition root files.

### `ToDo/Features`

Feature-first source tree. Each feature keeps its own `Presentation`, `Domain`, and `Data` folders when the feature needs all three layers.

- `BuyFeature`: remote catalog flow joined with locally persisted wishlist quantity.
- `CallFeature`: paginated contact-list flow with retry-aware remote loading.
- `SellFeature`: inventory create/edit/delete, filtering, paging, and local sell persistence.
- `SyncFeature`: pending sale queue, manual sync, replay coordination, and feature-owned application orchestration.

### `ToDo/Shared`

Cross-feature support code that should not belong to a single business feature.

- `AppError.swift`: shared validation, persistence, and networking error type.
- `AutoRetryCoordinator.swift`: reusable transient retry and backoff coordinator used by retry-aware features.
- `ConnectivityMonitoring.swift`: connectivity abstraction and live network monitor used by retry-aware features.
- `Presentation/`: shared presentation helpers and summary-building support code.
- `Infrastructure/Data/Remote/`: true cross-feature technical infrastructure used by multiple feature-owned repositories.

### `ToDoTests`

Feature-organized unit tests and shared test doubles.

- `Architecture`: fitness tests that enforce important structural boundaries.
- `Shared/TestDoubles`: reusable repositories and storage helpers for tests.

## Architectural Summary

The codebase follows feature-first physical organization with clean architecture inside each feature:

- `Features/<Feature>/Presentation`: UI and screen state.
- `Features/<Feature>/Domain`: business models, contracts, and use cases when they add business value beyond a direct repository call.
- `Features/<Feature>/Data`: concrete persistence and repository implementations.
- `App`: composition root and app lifecycle coordination.
- `Shared`: common support code and cross-feature technical infrastructure.

This file remains focused on the current structure and folder responsibilities of the app and test targets.

For `ToBuy`, the current active flow is:

- `BuyRepository` returns remote items using a `BuyCatalogQuery`
- `WishlistRepository` stores local quantity and persisted item details
- `LoadBuyCatalogUseCase` joins remote items with local wishlist quantity into `BuyCatalogListItem`
- `BuyRepositoryImp` lives under `Features/BuyFeature/Data` and uses the shared mock server from `Shared/Infrastructure/Data/Remote`

For `ToSell`, the current active flow is:

- `AppContainer` wires `SQLiteSellLocalDataSource` directly for sell inventory flows and `SyncRepositoryImp` for sync queue flows
- `RootView` owns the home summary state and mirrors feature view-model state into the summary view model
- `SQLiteSellLocalDataSource` owns SQLite inventory reads and local writes behind the sell data-source contract
- `SQLiteSellStore` remains the actor facade while `SQLiteSellItemStore`, `SQLitePendingSyncStore`, and `SQLiteSchemaManager` split sell-item, queued-sync, and schema responsibilities
- `SellRemoteGateway` defines the remote sell replay contract used by sync
- `ToSellViewModel` handles filter, refresh, paging, create, update, delete, and restore
- `SyncOrchestrator` calls `SyncRepository` directly for queued replay because a dedicated sync use case would be a pass-through wrapper
- `SyncViewModel` uses `SyncRepository` for queue loading and the orchestrator for manual sync
- `SyncRepositoryImp` syncs queued sell operations to the same backend used by `ToBuy` while keeping remote details behind the data-layer boundary
