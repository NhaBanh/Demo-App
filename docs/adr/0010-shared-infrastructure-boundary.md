# ADR 0010: Restrict Shared Data Code to Shared Infrastructure Only

## Context

The data layer originally included a `Data/Shared` folder that held only backend-facing infrastructure reused by both `ToBuy` and `ToSell`:

- a shared mock backend
- a canonical remote inventory DTO

That usage is legitimate, but a generic `Shared` name tends to become a dumping ground over time. Once that happens, unrelated cross-feature code accumulates in one place and the folder stops communicating why the code is shared.

## Decision

First, rename `Data/Shared` to `Data/SharedInfrastructure`.

After the broader feature-first source-tree refactor, keep the same boundary but place that code under `Shared/Infrastructure/Data`.

Use this folder only for technical infrastructure that is genuinely reused across multiple data features, such as:

- shared transport-facing mock servers
- canonical remote payloads that support multiple feature-owned repositories
- low-level adapters that are technical rather than business-owned

Do not use this shared infrastructure area for:

- business logic that belongs to one feature
- convenience dumping grounds for hard-to-place code
- domain-facing models that are only loosely related

If code is shared by a narrower business area in the future, prefer a more specific name than a global shared bucket.

## Consequences

This makes the folder's purpose more explicit and reduces the risk of structural drift. It also helps reviewers distinguish between business-shared logic and technical infrastructure shared for implementation reasons, even after the code moves under `Shared/Infrastructure/Data`.

The tradeoff is slightly longer paths and stricter placement decisions, but that cost is small compared with the clarity gained.
