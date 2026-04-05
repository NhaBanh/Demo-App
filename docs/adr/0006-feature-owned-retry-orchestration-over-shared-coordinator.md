# ADR 0006: Add Feature-Owned Retry Orchestration on Top of the Shared Retry Coordinator

## Context

ADR 0005 introduced a shared `AutoRetryCoordinator` and `ConnectivityMonitoring` abstraction so remote retry flows would not live entirely inside one view model.

That baseline still fits `To Call`, where `CallViewModel` directly uses the shared coordinator for a single screen-oriented remote load flow.

The sync runtime later grew beyond that shape. The current sync behavior needs to coordinate:

- manual sync triggers from the `Sync` screen
- automatic sync when connectivity returns
- delayed retry for transient failures in user-facing flows
- background refresh sync every 15 minutes
- different retry behavior for user-facing and background triggers
- coalescing overlapping triggers while a sync is already running
- publishing completion events back to the `Sync` presentation layer

Those responsibilities are broader than a reusable retry primitive, but still too feature-specific to move into `App` or a global shared service.

## Decision

Keep the generic retry primitive in shared code:

- `Shared/AutoRetryCoordinator.swift`
- `Shared/ConnectivityMonitoring.swift`

Add a feature-owned orchestration layer for sync in the current layer-first source tree:

- `ToDo/Application/Sync/SyncOrchestrator.swift`

The current split of responsibilities is:

- `AutoRetryCoordinator`: reusable retry state machine with policy-based schedules, reconnect retry support, and optional status messaging
- `SyncOrchestrator`: owns sync trigger intake, in-flight deduping, pending-trigger coalescing, retry-policy selection, connectivity-regained sync starts, and completion publishing
- `SyncRepository`: replays queued sell operations and reports retryable vs non-retryable failures upward
- `CallViewModel`: continues to use the shared retry coordinator directly for the simpler remote list flow

The shared coordinator now supports policy presets that match current product needs:

- `userFacing`: retries after 3s, 5s, and 10s, retries on reconnect, and emits status messages
- `backgroundSync`: no in-process retry schedule, no reconnect retry inside the coordinator, and no status messages

This keeps retry mechanics reusable while allowing feature-level orchestration to stay close to the business flow that needs it.

## Consequences

This makes the architecture more explicit:

- shared code owns the generic retry primitive
- feature `Application` code owns runtime coordination that spans multiple triggers and policies
- view models stay lighter because they no longer need to absorb sync-loop orchestration concerns

It also aligns the codebase with the existing `Application` layer rule in the architecture docs: feature-owned runtime orchestration should live in the application-layer area for that feature when it is broader than one use case but not truly cross-feature.

The tradeoff is that retry behavior is no longer described fully by the shared coordinator alone. Contributors now need to understand both the reusable retry primitive and the feature-specific orchestrator when changing sync behavior. That added complexity is acceptable because the current sync flow has materially different needs from the simpler `To Call` retry flow.
