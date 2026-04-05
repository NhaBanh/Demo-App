# Sync Module Features

## Purpose

Support offline-first `ToSell` changes by queueing local sell updates and syncing them to an API when connectivity is available.

This document combines both the feature overview and the main design decisions behind the `Sync` implementation.

## Core Features

- Offline-first sell change flow
- Manual sync
- Auto sync on connectivity regain
- Background refresh sync every 15 minutes
- Pending sync queue

## User Experience

- Queue sell changes even while offline
- Attempt sync again when network connectivity returns
- Schedule background refresh every 15 minutes and attempt 1 sync run per refresh
- Show pending sell sync items
- Show successful sync operations for the current app session
- Trigger manual sell sync
- Show loading, success, and error states

## Data

The module works with:

- `SellItem`
- `QueuedSellOperation`

## Key Decisions

### Offline-first queue before network replay

The sync flow starts from locally persisted sell changes rather than from live UI actions.

That keeps `To Sell` responsive while making replay timing explicit and recoverable.

### Feature-owned orchestration for multi-trigger sync

`SyncOrchestrator` owns manual triggers, reconnect triggers, background-task triggers, retry integration, and in-flight deduping.

That logic is broader than a single use case but still specific to sync behavior, so it belongs in the feature-owned `Application` layer.

### Different retry policy for user-facing and background flows

Retry only applies to transient network failures.

User-facing triggers use a fast backoff schedule of 3s, 5s, and 10s with reconnect-aware retry, while background refresh performs one attempt per wake without an in-process retry loop.

### Direct queue-focused Sync screen

The `Sync` screen shows queued sell operations directly and also keeps an in-memory history of successful sync operations for the current app session.

Entering the Sync tab refreshes local state but does not auto-run sync; manual replay stays explicit.

## Architecture Notes

- `Features/SyncFeature/Presentation`: SwiftUI screen and view model
- `Features/SyncFeature/Domain/Entities/QueuedSellOperation.swift`: generalized queued sell operation model for replaying offline-first changes
- `Features/SyncFeature/Domain/Repositories/SyncRepository.swift`: sync-specific contract for pending queue state and replay, used directly by the Sync screen for queue inspection
- `Features/SyncFeature/Application/SyncOrchestrator.swift`: feature-owned sync coordinator that owns trigger intake, connectivity regain handling, in-flight deduping, retry integration, and direct queued-replay calls to the sync repository
- `App/SellSyncBackgroundTaskManager.swift`: background app-refresh registration and scheduling for periodic sell sync attempts
- `Features/SellFeature/Data/Local/SQLiteSellLocalDataSource.swift`: local sell inventory data source backed by SQLite
- `Features/SyncFeature/Data/SyncLocalDataSource.swift`: sync-facing local queue contract used by the sync repository implementation
- `Features/SyncFeature/Data/Local/SQLiteSyncLocalDataSource.swift`: local sync queue data source backed by the shared SQLite sell store
- `Features/SyncFeature/Data/SyncRepositoryImp.swift`: syncs generalized queued sell operations to the shared backend and reports retryable failures upward
- `Features/SellFeature/Data/Local/SQLite/SQLiteSellStore.swift`: stores generalized pending sell sync records
- `Features/SyncFeature/Data/SellRemoteGateway.swift`: sell-specific remote replay contract used by the sync repository implementation
- `Features/SyncFeature/Data/Remote/RemoteSellItemDTO.swift`: sync-owned remote transport model for replaying queued sell operations
- `Features/SyncFeature/Data/Remote/MockSellRemoteGateway.swift`: mock remote sync gateway for sell operations
- `Shared/Infrastructure/Data/Remote/RemoteInventoryItemDTO.swift`: canonical backend inventory record shared by `ToBuy` and `ToSell`
- `Shared/Infrastructure/Data/Remote/MockInventoryServer.swift`: shared mock backend currently referenced by To Buy and To Sell
- `Shared/AutoRetryCoordinator.swift`: retry backoff and reconnect-aware retry policy used by the orchestrator
- `Shared/ConnectivityMonitoring.swift`: connectivity abstraction used by the orchestrator and retry policy

## Diagram

```mermaid
sequenceDiagram
    actor User
    participant SyncView as "SyncView"
    participant SyncVM as "SyncViewModel"
    participant Orchestrator as "SyncOrchestrator"
    participant Retry as "AutoRetryCoordinator"
    participant SyncRepo as "SyncRepository / SyncRepositoryImp"
    participant LocalDS as "SQLiteSyncLocalDataSource"
    participant SQLite as "SQLiteSellStore"
    participant RemoteDS as "SellRemoteGateway / MockSellRemoteGateway"
    participant API as "MockInventoryServer / Shared Backend"

    User->>SyncView: Tap "Sync Sell Changes"
    SyncView->>SyncVM: syncNow()
    SyncVM->>Orchestrator: trigger(.manual)
    alt Device is offline or another sync is already running
        Orchestrator-->>SyncVM: nil
        SyncVM-->>SyncView: show "Sync requested." and refresh queue
    else Sync starts now
        Orchestrator->>Retry: reset()
        Orchestrator->>SyncRepo: syncPendingChanges()
        SyncRepo->>LocalDS: pendingSyncOperations()
        LocalDS->>SQLite: SELECT pending queue
        SQLite-->>LocalDS: queued operations
        LocalDS-->>SyncRepo: queue payloads

        loop For each queued operation
            SyncRepo->>RemoteDS: sync(operation)
            alt Create or update
                RemoteDS->>API: create/update request
            else Delete
                RemoteDS->>API: delete request
            end
            alt Sync succeeds
                API-->>RemoteDS: success
                RemoteDS-->>SyncRepo: synced
            else Retryable failure
                API-->>RemoteDS: transient network error
                RemoteDS-->>SyncRepo: retryable error
            else Non-retryable failure
                API-->>RemoteDS: validation or server rejection
                RemoteDS-->>SyncRepo: non-retryable error
            end
        end

        SyncRepo->>LocalDS: removePendingOperations(syncedIDs)
        LocalDS->>SQLite: DELETE synced pending rows
        SQLite-->>LocalDS: rows removed
        LocalDS-->>SyncRepo: queue cleanup complete

        alt At least one non-retryable failure occurred
            SyncRepo-->>Orchestrator: throw first non-retryable error
            Orchestrator->>Retry: handleFailure(error) is rejected
            Orchestrator->>Retry: reset()
        else At least one retryable failure occurred
            SyncRepo-->>Orchestrator: AppError.transientNetwork
            Orchestrator->>Retry: schedule delayed retry
        else All queued operations synced
            SyncRepo-->>Orchestrator: synced operations
            Orchestrator->>Retry: reset()
            Orchestrator-->>SyncVM: completionPublisher event
            SyncVM-->>SyncView: prepend successful session rows
        end

        SyncVM-->>SyncView: refresh queue and show toast
    end
```

```mermaid
sequenceDiagram
    participant BGTask as "SellSyncBackgroundTaskManager"
    participant Connectivity as "ConnectivityMonitoring"
    participant Orchestrator as "SyncOrchestrator"
    participant Retry as "AutoRetryCoordinator"
    participant SyncRepo as "SyncRepository / SyncRepositoryImp"
    participant LocalDS as "SQLiteSyncLocalDataSource"
    participant SQLite as "SQLiteSellStore"
    participant RemoteDS as "SellRemoteGateway / MockSellRemoteGateway"
    participant API as "MockInventoryServer / Shared Backend"
    participant UI as "SyncViewModel"

    opt Connectivity returns
        Connectivity-->>Orchestrator: online event
        Orchestrator->>Retry: reset() for user-facing policy
        Orchestrator->>SyncRepo: syncPendingChanges()
    end

    opt Background refresh wake
        BGTask->>Orchestrator: trigger(.backgroundTask)
        Orchestrator->>Retry: reset() for background policy
        Orchestrator->>SyncRepo: syncPendingChanges()
    end

    SyncRepo->>LocalDS: pendingSyncOperations()
    LocalDS->>SQLite: SELECT pending queue
    SQLite-->>LocalDS: queued operations
    LocalDS-->>SyncRepo: pending operations

    loop Replay queued operations
        SyncRepo->>RemoteDS: sync(operation)
        alt Success
            RemoteDS->>API: send queued change
            API-->>RemoteDS: success
            RemoteDS-->>SyncRepo: synced
        else Retryable failure
            RemoteDS->>API: send queued change
            API-->>RemoteDS: transient error
            RemoteDS-->>SyncRepo: retryable failure
        else Non-retryable failure
            RemoteDS->>API: send queued change
            API-->>RemoteDS: non-retryable failure
            RemoteDS-->>SyncRepo: failure
        end
    end

    SyncRepo->>LocalDS: removePendingOperations(syncedIDs)
    LocalDS->>SQLite: DELETE synced queue records
    SQLite-->>LocalDS: rows removed
    LocalDS-->>SyncRepo: cleanup complete

    alt Trigger was connectivity regained and a retryable failure occurs
        SyncRepo-->>Orchestrator: AppError.transientNetwork
        Orchestrator->>Retry: schedule delayed retry or retry on reconnect
        Retry-->>Orchestrator: trigger(.retry) later
    else Trigger was background task and a retryable failure occurs
        SyncRepo-->>Orchestrator: AppError.transientNetwork
        Orchestrator->>Retry: handleFailure() rejected by background policy
        Orchestrator->>Retry: reset()
    else Sync completes with at least one success
        SyncRepo-->>Orchestrator: synced operations
        Orchestrator-->>UI: publish completionPublisher event
        UI-->>UI: refresh counts, queue state, and toast
    end
```

## Summary

The `Sync` module is designed as an offline-first replay system for sell changes rather than as a direct network workflow. The main design goals are to preserve local-first sell behavior, make retry and trigger policies explicit, and keep sync orchestration isolated in a feature-owned coordinator.
