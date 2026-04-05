# ADR 0003: Use AppContainer as the Dependency Injection Composition Root

## Context

Several features depend on repository abstractions and use cases, and some features can be backed by different concrete persistence implementations. Without a single composition root, dependency wiring can leak into screens or feature logic, making backend selection harder to reason about.

## Decision

Use `AppContainer` and its feature-specific extensions as the composition root. This layer is responsible for:

- constructing repositories and use cases
- wiring feature view models
- composing dependencies from the current layer-first source tree, such as `ToDo/Domain/<Feature>`, `ToDo/Data/<Feature>`, and `ToDo/Presentation/<Feature>`
- selecting the active sell persistence backend
- keeping sync wired to the SQLite-backed flow

Views and view models should receive already-composed dependencies and should not instantiate concrete repositories themselves.

## Consequences

This centralizes wiring decisions and keeps architecture rules enforceable. The tradeoff is that `AppContainer` becomes an important maintenance point, so backend changes and feature assembly rules must stay well documented.
