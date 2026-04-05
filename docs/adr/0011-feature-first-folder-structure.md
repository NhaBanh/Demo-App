# ADR 0011: Organize Source Code Under Feature-First Folders

## Context

The app already used clean architecture boundaries and had gradually moved `Presentation`, `Domain`, and `Data` closer to feature-first organization. Even so, the top-level source tree still separated those layers into different root folders, which meant one business change still required moving between distant parts of the tree.

For this technical test, the feature boundaries are strong:

- `BuyFeature`
- `CallFeature`
- `SellFeature`
- `SyncFeature`

Each feature owns presentation state, business rules, repository contracts, and data implementations. A full feature-first structure makes that ownership visible and keeps business changes localized.

## Decision

Move application source files under `ToDo/Features/<Feature>/...` while keeping `App`, `Shared`, and assets at the top level.

The structure now follows this style:

- `ToDo/App/...`
- `ToDo/Features/BuyFeature/{Data,Domain,Presentation}`
- `ToDo/Features/CallFeature/{Data,Domain,Presentation}`
- `ToDo/Features/SellFeature/{Data,Domain,Presentation}`
- `ToDo/Features/SyncFeature/{Application,Data,Domain,Presentation}`
- `ToDo/Shared/...`

Within each feature, the clean architecture layers remain explicit:

- `Presentation`: SwiftUI views, view models, feature-scoped UI components
- `Application`: feature-scoped orchestrators and coordinators that manage runtime flow without becoming global app infrastructure
- `Domain`: entities, models, repository contracts, use cases
- `Data`: repository implementations, local and remote data-source helper contracts, backend-specific data-source implementations, and DTOs

Cross-feature technical infrastructure does not move into a feature folder. It lives under:

- `ToDo/Shared/Infrastructure/...`

`App` stays as the composition root and lifecycle coordination layer. `Shared` stays reserved for cross-feature support code rather than business-owned feature logic.

Within `Data`, abstraction and implementation naming should stay explicit:

- repository ports stay in `Domain`
- helper contracts such as `WishlistLocalDataSource` or `SellRemoteGateway` stay in feature `Data`
- concrete implementations use backend-revealing names such as `SwiftData...`, `SQLite...`, or `Mock...`

## Consequences

This improves feature locality, makes the modular-monolith structure easier to explain, and reduces navigation cost when working on one business area. It also aligns the physical folder layout with how the test brief and review feedback describe the app.

The tradeoff is that cross-feature architectural views are now less visible from the top level. It also means the allowed feature shape is no longer a strict three-layer-only rule, because some features may need a small `Application` layer for orchestration. To offset that, the project keeps explicit architecture docs, ADRs, and automated fitness tests for both layer purity and allowed top-level feature folders.
