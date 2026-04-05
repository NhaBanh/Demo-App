# Architecture Guideline

## Goal

This project follows `MVVM` in the presentation layer and `Clean Architecture` across the app.

Related ADRs:

- `docs/adr/0001-layered-clean-architecture.md`
- `docs/adr/0002-to-call-remote-first-module.md`
- `docs/adr/0003-appcontainer-composition-root.md`
- `docs/adr/0008-feature-first-domain-organization.md`
- `docs/adr/0009-domain-boundary-fitness-functions.md`
- `docs/adr/0010-shared-infrastructure-boundary.md`
- `docs/adr/0011-feature-first-folder-structure.md`
- `docs/adr/0012-pass-through-use-cases-may-be-skipped.md`

The architecture should help us:

- keep business logic independent from UI
- make features easy to test
- isolate data sources behind protocols
- support both `SQLite` and `SwiftData` cleanly
- make the codebase easier to extend during the technical test

## How to Read This Document

Use this file as the source of truth for current architecture rules and boundaries.

Use `docs/adr/` for decision history and rationale behind the major architecture choices.

## High-Level Structure

The app is organized by feature first, while still keeping clean architecture layers explicit inside each feature.

- `App`
  - app entry point
  - dependency wiring
  - root navigation
  - app-level orchestration
- `Features/<Feature>/Presentation`
  - SwiftUI screens
  - view models
  - feature-scoped UI components
- `Features/<Feature>/Application`
  - feature-scoped orchestration services
  - runtime coordination across use cases or triggers
- `Features/<Feature>/Domain`
  - entities
  - read models
  - repository contracts
  - use cases
  - business rules
- `Features/<Feature>/Data`
  - repository implementations
  - remote services
  - local persistence
- `Shared`
  - cross-feature support types
  - shared presentation helpers
  - shared technical infrastructure

## MVVM Rule

Use `MVVM` only in feature `Presentation` folders.

- `View`
  - renders UI
  - forwards user actions
  - should not contain business logic
- `ViewModel`
  - prepares UI state
  - calls use cases
  - handles loading, error, and success states
  - should not talk directly to SQLite, SwiftData, or networking
- `Model`
  - in this project, domain entities and read models are the source of truth for app behavior

## Clean Architecture Rule

Dependencies should point inward inside each feature:

`Presentation -> Application -> Domain <- Data`

That means:

- feature `Presentation` may depend on feature `Application` and feature `Domain`
- feature `Application` depends on feature `Domain`
- feature `Data` depends on feature `Domain`
- feature `Domain` depends on nothing from feature `Presentation`, feature `Application`, or feature `Data`

`App` may compose feature dependencies but should not absorb feature business logic.

## Architectural Fitness Rule

Important architectural boundaries should be enforced by tests when practical, not only by documentation.

Current fitness function:

- `ToDoTests/Architecture/DomainBoundaryFitnessTests.swift` scans `ToDo/Features/*/Domain`
- the test fails if any Domain file imports `SwiftUI`, `SwiftData`, `SQLite3`, or `UIKit`
- the test allows `Application`, `Data`, `Domain`, and `Presentation` as valid top-level feature folders
- the test also fails if any `Application` file imports `SwiftUI`, `SwiftData`, `SQLite3`, or `UIKit`

Why this form:

- the app is built as one Swift module, so feature folders are not separately importable Swift modules
- framework-level import checks are the most reliable lightweight guardrail for this codebase

Expectation:

- run this architecture test alongside the normal unit test suite
- extend the rule set if the codebase introduces new outer-layer frameworks that Domain must avoid
- use `Application` only when a feature needs orchestration broader than one use case but too feature-specific for `App` or `Shared`

## Layer Responsibilities

### 1. App Layer

Files in `App/` are responsible for composition only.

Use this layer for:

- `ToDoApp`
- dependency container
- root-level feature wiring
- shared presentation-state coordination that belongs above any single feature, such as the home summary state
- app-level coordinators that orchestrate lifecycle-driven flows across features
- background task registration and scheduling that coordinate app-level feature work
- feature factory methods that assemble view models and use cases

Do not put feature business logic here.

### 2. Feature Presentation Layer

Files in `Features/<Feature>/Presentation/` own UI and screen state for one feature.

Current feature folders:

- `Features/BuyFeature/Presentation`
- `Features/CallFeature/Presentation`
- `Features/SellFeature/Presentation`
- `Features/SyncFeature/Presentation`

Each feature should usually contain:

- `FeatureView.swift`
- `FeatureViewModel.swift`

Presentation rules:

- views are small and declarative
- view models own screen state
- view models call use cases when they add business value through validation, normalization, orchestration, or clearer action boundaries
- view models may call domain repository protocols directly when a dedicated use case would only be a pass-through wrapper
- no SQL, no persistence code, no raw API mapping in views

### 3. Feature Application Layer

Use `Features/<Feature>/Application/` for feature-owned runtime orchestration.

Current feature folders:

- `Features/SyncFeature/Application`

Responsibilities:

- coordinate retries, connectivity callbacks, or background triggers for one feature
- coalesce overlapping requests or triggers
- publish feature-level completion events when the flow needs them
- keep stateful coordination out of view models, repositories, and `App`

Rules:

- `Application` may depend on feature `Domain` contracts and shared technical helpers
- `Application` should not import `SwiftUI`, `SwiftData`, `SQLite3`, or `UIKit`
- `Application` should remain feature-scoped; move code to `Shared` only when multiple features genuinely need it
- do not use `Application` as a dumping ground for logic that belongs in a use case or repository

### 4. Feature Domain Layer

The `Domain` layer contains the app rules for one feature.

Current feature folders:

- `Features/BuyFeature/Domain`
- `Features/CallFeature/Domain`
- `Features/SellFeature/Domain`
- `Features/SyncFeature/Domain`

Within a feature folder, use lightweight technical subfolders when they improve navigation:

- `Entities`
- `Models`
- `Repositories`
- `UseCases`

Domain rules:

- keep each feature's entities, repository contracts, query/read models, and use cases close together inside the same feature folder
- entities are framework-light and business-focused
- read models represent use-case input/output when the result is not a core entity
- repository definitions are protocols only
- data-source helper protocols that support repository implementations belong in `Data`, not `Domain`
- use cases express actions clearly when they add business meaning, especially for validation-heavy flows and multi-source orchestration
- pass-through flows may remain repository-driven by design when they add no extra business behavior beyond forwarding the call

Examples:

- `CreateSellItemUseCase`
- `LoadBuyCatalogUseCase`

### 5. Feature Data Layer

The `Data` layer implements the contracts defined in the matching feature `Domain`.

Current feature folders:

- `Features/BuyFeature/Data`
- `Features/CallFeature/Data`
