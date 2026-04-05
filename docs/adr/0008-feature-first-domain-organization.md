# ADR 0008: Organize the Domain Layer by Feature First

Status: Obsolete, superseded by `0011-feature-first-folder-structure.md`

## Context

The project had already started moving toward feature ownership, but the structure was still inconsistent.

The `Domain` layer still used a technical-first split such as:

- `Domain/Entities/...`
- `Domain/Models/...`
- `Domain/Repositories/...`
- `Domain/UseCases/...`

At the same time, other parts of the app were already showing feature ownership in a looser form:

- presentation work was mostly discussed and implemented as feature-specific screens and view models
- app composition already used feature-oriented `AppContainer` extensions for dependency assembly
- data and presentation code still lived under top-level technical roots such as `ToDo/Data/<Feature>` and `ToDo/Presentation/<Feature>`

So the codebase was in a transitional state:

- feature ownership was already visible in naming and wiring
- the physical source tree was still only partly feature-first
- `Domain` remained the clearest structural mismatch because one business change still required jumping between several technical branches

A change to `SellFeature`, for example, could still require bouncing between separate `Entities`, `Models`, `Repositories`, and `UseCases` folders even though the work belonged to one business area.

Because this technical test emphasizes explainability and architectural clarity, the structure should make feature boundaries easy to see and easy to walk through during review, not just inside `Domain`.

## Decision

Keep the layered architecture, but organize the `Domain` layer by feature first as the next step.

The domain structure should move toward this style:

- `ToDo/Domain/Home/...`
- `ToDo/Domain/BuyFeature/...`
- `ToDo/Domain/CallFeature/...`
- `ToDo/Domain/SellFeature/...`
- `ToDo/Domain/SyncFeature/...`

This change should also stay aligned with the broader feature-ownership direction already visible elsewhere:

- presentation code should continue to be owned and discussed by feature
- app composition should continue using feature-oriented container extensions and feature assembly boundaries

Within each feature folder, group domain types by responsibility when the feature has enough files to justify it:

- `Entities/`
- `Models/`
- `Repositories/`
- `UseCases/`

## Consequences

This increased functional cohesion and made feature-level business changes easier to localize in the business layer that had been lagging furthest behind. It also made the architecture easier to explain because `Domain` now matched the feature boundaries that were already becoming visible in presentation naming and app wiring.
