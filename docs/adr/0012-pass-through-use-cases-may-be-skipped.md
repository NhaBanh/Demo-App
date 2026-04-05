# ADR 0012: Pass-Through Use Cases May Be Skipped

## Context

The project uses feature-first clean architecture and generally models business actions with explicit use cases.

That rule works well when a use case adds business value, such as validation, normalization, orchestration, mapping, or a clearly named reusable action.

However, some flows only forward a call from presentation to one domain repository contract and return the result unchanged. Requiring a dedicated use case for every such pass-through flow adds boilerplate without adding policy, validation, orchestration, or clearer behavior.

Without an explicit rule, those direct repository calls can look inconsistent or unfinished even when they are intentionally simpler.

## Decision

Presentation code may bypass a dedicated use case and call a domain repository contract directly when all of the following are true:

- the presentation layer depends only on a domain repository protocol, not on data-layer types
- the flow does not add business policy, validation, normalization, mapping, orchestration, caching, or cross-repository coordination
- a dedicated use case would be a pass-through wrapper only

Use cases remain the default for:

- workflows with validation or normalization
- orchestration across multiple repositories or services
- reusable business actions whose naming improves clarity

If a direct repository call later grows business rules or coordination, promote it to a dedicated use case at that point.

## Consequences

- the architecture stays intentionally pragmatic instead of mechanically adding pass-through types
- view models may call domain repository methods directly when the call is only a thin pass-through
- mutation paths often still benefit from use cases, but they are not required when no business value is added
- direct repository access should remain narrow and should not leak data-layer details into presentation
