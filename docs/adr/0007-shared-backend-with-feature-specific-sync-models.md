# ADR 0007: Shared Backend with Feature-Specific Sync Models

## Context

The project originally treated `ToBuy` as a remote-backed module and `ToSell` as a local SQLite-backed module with a sold-item sync queue.

As the implementation evolved, it became clear that:

- `ToBuy` and `ToSell` should use the same backend surface
- `ToSell` needs to sync more than just a single sold action over time
- the app should remain local-first for `ToSell`
- the existing architecture should still keep feature boundaries clear

A tempting simplification would be to make `ToBuy` and `ToSell` share one common entity because they now talk to the same backend. That would reduce the number of types in the short term, but it would also blur feature intent.

The two modules represent different business concepts:

- `ToBuy` is a remote catalog and wishlist flow
- `ToSell` is a local inventory and outbound sync flow

Even when the backend is shared, the feature semantics, UI behavior, and sync lifecycle remain different.

At the same time, the original sold-only sync queue in `ToSell` was too narrow for future growth. Once `ToSell` needs to sync broader inventory changes, the queue must carry operation type and enough payload to replay actions against the backend.

## Decision

Use one shared backend infrastructure for both `ToBuy` and `ToSell`, but keep feature-specific domain models, DTOs, and repository contracts.

The app will follow these rules:

- `ToBuy` and `ToSell` may use the same backend service or mock server
- `BuyItem` and `SellItem` remain separate domain entities
- remote DTOs remain feature-specific
- `ToSell` continues to treat local SQLite storage as the source of truth for user-driven inventory changes
- sync behavior is modeled as queued sell operations, not as direct network calls from views or view models

For the current generalized sync design:

- the shared mock backend is used by both `ToBuy` and `ToSell`
- the `ToSell` queue stores generalized sell sync operations
- the `Sync` screen renders queued sell operations directly from the shared queue
- the app supports manual sync from the `Sync` screen
- the app also schedules background refresh sync attempts

This means the codebase now exposes the broader sync model directly in both the runtime flow and the current user-facing sync screen.

## Consequences

Positive consequences:

- backend sharing is possible without collapsing domain boundaries
- `ToBuy` and `ToSell` can evolve independently even when backed by the same server
- `ToSell` keeps its local-first behavior, which matches the assignment requirement for SQLite-backed inventory
- the sync system now has a path to support create, update, delete, and sold operations
- dependency flow stays aligned with clean architecture: `Presentation -> Domain <- Data`

Tradeoffs:

- more types exist overall because buy and sell models are intentionally not merged
- the sync flow has more moving parts because local inventory writes, queued replay, reconnect handling, and background refresh are kept explicit

Follow-up implications:

- background sync is now part of the active runtime flow and must stay aligned with app lifecycle wiring and `BGTaskScheduler` configuration
