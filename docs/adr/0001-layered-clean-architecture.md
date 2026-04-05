# ADR 0001: Use Layered Clean Architecture with MVVM in Presentation

## Context

The project needed a simple starting architecture that kept UI, business rules, and data access separated while remaining easy to build and explain during the technical test.

## Decision

Use a layered structure with these responsibilities:

- `App`: composition root and dependency wiring
- `Presentation`: SwiftUI views and view models
- `Application`: optional orchestration layer for runtime coordination broader than one use case
- `Domain`: entities, repository contracts, models, and use cases
- `Data`: repository implementations, data-source helper contracts, and persistence details
- `Shared`: cross-cutting support types

Use `MVVM` only inside the `Presentation` layer. `ViewModel` types may call use cases, but they should not talk directly to persistence or networking details.

## Consequences

This gives the project a clear baseline structure, keeps business rules testable, and leaves room for the folder organization to evolve later without changing the core dependency rule.
