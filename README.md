# ToDo Mobile Technical Test

## Quick Start

Requirements:

- Xcode with iOS 18 SDK support
- An iPhone simulator running iOS 18 or newer

Run locally:

1. Open [ToDo.xcodeproj](ToDo.xcodeproj) in Xcode.
2. Select the `ToDo` scheme.
3. Run the app on an iPhone simulator running iOS 18 or newer.

## Mock API / Data Setup

No separate backend service is required.
No manual mock-data setup is required either, because the project already includes the in-app mock services and seeded sample data needed for local development and review.

The project uses in-app mock remote services for the API-backed modules:

- [MockToCallServer.swift](ToDo/Features/CallFeature/Data/Remote/MockToCallServer.swift)
- [MockInventoryServer.swift](ToDo/Shared/Infrastructure/Data/Remote/MockInventoryServer.swift)

Local persistence:

- Wishlist data uses SwiftData.
- Sell inventory and pending sync operations use SQLite.
- The required SQLite table `ItemToSell` is created in [SQLiteSchemaManager.swift](ToDo/Features/SellFeature/Data/Local/SQLite/SQLiteSchemaManager.swift).

Using both `SQLite` and `SwiftData` is intentional. It demonstrates that the `Domain` layer and feature flows depend on repository contracts rather than a persistence technology, while also showing the ability to choose the right storage approach for different requirements.

## Architecture

The app uses a **feature-first** Clean Architecture approach with explicit layers:

- `Presentation`
- `Application` when feature-level orchestration is needed
- `Domain`
- `Data`

Dependency wiring is centralized in:

- [AppContainer.swift](ToDo/App/DI/AppContainer.swift)

### Why This Structure

The current structure aims to be:

- scalable enough to support feature growth without pushing business logic into views
- maintainable enough that UI, business rules, persistence, and orchestration stay separated
- testable enough that important logic can be verified without requiring the whole app runtime
- understandable enough that a reviewer can navigate the project quickly and see why each layer exists

The project is structured to move beyond a simple demo toward a codebase that can scale under additional features and maintenance pressure. It emphasizes small, explicit responsibilities, localized feature ownership, clean boundaries, and documentation that explains both the structure and the reasoning behind it. The broader switch to a feature-first source tree is documented in [0011-feature-first-folder-structure.md](docs/adr/0011-feature-first-folder-structure.md).

### Project Structure

At a high level, the repository is organized like this:

- `ToDo/App`: app entry point, root navigation, and dependency wiring
- `ToDo/Features`: feature-first source tree with `Presentation`, `Application` when needed, `Domain`, and `Data`
- `ToDo/Shared`: cross-feature support code and shared technical infrastructure
- `ToDoTests`: architecture and feature tests

For the current folder layout and responsibilities, see [project-structure.md](docs/project-structure.md).

### Engineering Principles

The implementation is guided by practical application of:

- `SOLID`: clear responsibilities, repository abstractions, dependency injection, and inward dependency flow
- `KISS`: pass-through use cases may be skipped when they do not add business value
- `DRY`: shared code is extracted only when reuse is real, such as retry, connectivity, and infrastructure helpers

The overall direction is to reduce accidental complexity, keep feature ownership local, and provide documentation that stays easy to follow during review and maintenance.

Architecture documentation:

- [ArchitectureGuideline.md](docs/ArchitectureGuideline.md)
- [project-structure.md](docs/ProjectStructure.md)

## Tests

Unit tests live in [ToDoTests](ToDoTests).

Run tests from Xcode.

## Features Overview

### `To Call`: remote-backed list with pagination, filtering via search, retry behavior, pull to refresh, and last-synced timestamp

`To Call` is implemented as a remote-first contacts workflow. It keeps remote loading concerns explicit while avoiding unnecessary local persistence.

Current `To Call` behavior includes:

- Previous/next pagination with page metadata managed by the view model
- Search filtering across contact name, company, and phone number
- User-initiated refresh and retry actions
- Automatic retry handling for transient failures through a shared retry coordinator
- Last-synced timestamp display so the user can judge freshness
- Loading, error, and retry-status feedback

Supporting docs:

- [CallModuleFeature.md](docs/CallModuleFeature.md)

Relevant ADRs:

- [0002-to-call-remote-first-module.md](docs/adr/0002-to-call-remote-first-module.md)
- [0005-shared-connectivity-aware-retry-coordinator.md](docs/adr/0005-shared-connectivity-aware-retry-coordinator.md)
- [0012-pass-through-use-cases-may-be-skipped.md](docs/adr/0012-pass-through-use-cases-may-be-skipped.md)

### `To Buy`: remote-backed catalog with sorting, filtering, paging, detail view, and local wishlist persistence

`To Buy` is implemented as a remote catalog workflow enriched with local wishlist state. The remote API remains the source of truth for catalog data, while local persistence stores user-specific wishlist information.

Current `To Buy` behavior includes:

- Remote paged catalog loading
- Sorting by title, price ascending, and price descending
- Filtering by availability and category
- Detail view for each item
- Local wishlist persistence through `SwiftData`
- Catalog rendering that merges remote items with local wishlist quantity
- Handling for unavailable or removed catalog items in the wishlist flow

Supporting docs:

- [BuyModuleFeature.md](docs/BuyModuleFeature.md)

Relevant ADRs:

- [0004-to-buy-catalog-with-local-wishlist-snapshots.md](docs/adr/0004-to-buy-catalog-with-local-wishlist-snapshots.md)
- [0007-shared-backend-with-feature-specific-sync-models.md](docs/adr/0007-shared-backend-with-feature-specific-sync-models.md)
- [0012-pass-through-use-cases-may-be-skipped.md](docs/adr/0012-pass-through-use-cases-may-be-skipped.md)

### `To Sell`: SQLite-backed local inventory with create, update, delete, bulk delete, undo delete, validation, filtering, and paging

`To Sell` is implemented as a local-first inventory workflow backed by `SQLite`. This satisfies the assignment requirement for an `ItemToSell` table while keeping local writes reliable and explicit.

Current `To Sell` behavior includes:

- Local paged inventory loading
- Create and update flows with validation
- Inline editing directly from the list
- Bulk delete support
- Undo delete support
- Filtering by stock state
- Local-first persistence for all inventory mutations
- Automatic queueing of sync work for create, update, and delete actions

Supporting docs:

- [SellModuleFeature.md](docs/SellModuleFeature.md)

Relevant ADRs:

- [0007-shared-backend-with-feature-specific-sync-models.md](docs/adr/0007-shared-backend-with-feature-specific-sync-models.md)
- [0012-pass-through-use-cases-may-be-skipped.md](docs/adr/0012-pass-through-use-cases-may-be-skipped.md)

### `Sync`: offline-first queued sell sync with manual sync, connectivity-triggered retry, and background refresh scheduling

`Sync` goes beyond a minimal direct API retry flow by using a persistent local `QueuedSellOperation` store. User actions write locally first, and later manual, reconnect, retry, and background triggers replay queued operations against the backend.

This makes the sync flow more explicit than the minimum brief while intentionally keeping conflict resolution and retry or reconciliation policies lightweight, since those areas depend heavily on real backend contracts and server-side behavior.

Current `Sync` behavior includes:

- Offline-first sell change handling
- Persistent pending queue for sell operations
- Manual sync from the `Sync` screen
- Retry when connectivity returns
- Background refresh scheduling every 15 minutes
- In-flight deduping and trigger coordination through a feature-owned orchestrator
- Session-level display of successfully synced operations

Supporting docs:

- [SyncModuleFeature.md](docs/SyncModuleFeature.md)

Relevant ADRs:

- [0003-appcontainer-composition-root.md](docs/adr/0003-appcontainer-composition-root.md)
- [0006-feature-owned-retry-orchestration-over-shared-coordinator.md](docs/adr/0006-feature-owned-retry-orchestration-over-shared-coordinator.md)
- [0007-shared-backend-with-feature-specific-sync-models.md](docs/adr/0007-shared-backend-with-feature-specific-sync-models.md)

### App-wide counters and summary state shown on the Home screen

The `Home` screen acts as the entry point for all four modules and surfaces lightweight summary state.

Current `Home` behavior includes:

- Four module entry points: `To Call`, `To Buy`, `To Sell`, and `Sync`
- Summary counters for call priority mix, buy availability and wishlist state, total sell inventory, and pending sync work
- Counter refresh driven by module state changes and sync completion events
