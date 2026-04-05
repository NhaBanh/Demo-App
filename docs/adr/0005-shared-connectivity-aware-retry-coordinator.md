# ADR 0005: Use a Shared Connectivity-Aware Retry Coordinator for Remote Retry Flows

## Context

The `To Call` module needs more than a simple manual retry button. The chosen behavior includes:

- retry only for transient failures
- exponential backoff
- immediate retry when connectivity returns
- user-visible retry status
- a manual retry path that still remains available

The first implementation placed most of this logic directly in `CallViewModel`. That worked functionally, but it made the view model responsible for a reusable retry state machine. As more remote features are added, duplicating the same retry policy in each screen would make the code harder to scale and maintain.

## Decision

Move the retry state machine into a shared coordinator:

- `Shared/AutoRetryCoordinator.swift`

Support that coordinator with a connectivity abstraction:

- `Shared/ConnectivityMonitoring.swift`

The split of responsibilities is:

- `ViewModel`: trigger loads, expose retry state to the UI, and respond to user actions
- `AutoRetryCoordinator`: classify retryable failures, apply backoff, pause while offline, and retry on reconnect
- `Repository`: perform the fetch and throw typed errors such as transient network failures

## Consequences

This makes retry behavior reusable and easier to evolve across multiple remote modules. It also keeps feature view models focused on screen state instead of low-level retry orchestration.

The tradeoff is a small increase in shared infrastructure. That infrastructure needs good documentation so future contributors know when to reuse it versus when a feature-specific retry rule is still acceptable.
