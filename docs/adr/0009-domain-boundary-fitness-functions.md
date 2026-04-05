# ADR 0009: Enforce Domain Boundaries with Automated Fitness Functions

## Context

The project already documents clean architecture boundaries, especially the rule that `Domain` must remain independent of `Presentation` and `Data`. Documentation and code review help, but they are not enough on their own. Under delivery pressure, it is easy for a convenience import or framework dependency to slip into the wrong layer and slowly erode the architecture.

In Swift, the project is built as a single app module, so folders like `Data` and `Presentation` are not imported as separate Swift modules. That means a Java-style rule like "fail if Domain imports Data" does not translate directly.

## Decision

Add an automated architecture fitness test in the test target that scans the `ToDo/Domain/*` source tree and fails if Domain files import framework dependencies that belong to outer layers.

The first enforced rule is:

- Domain files must not import `SwiftUI`
- Domain files must not import `SwiftData`
- Domain files must not import `SQLite3`
- Domain files must not import `UIKit`

This keeps the Domain layer framework-light and prevents direct dependency on UI, persistence, and platform presentation concerns.

## Consequences

This turns an architectural guideline into an executable guardrail and makes regressions visible in CI and local test runs. It also gives reviewers a concrete enforcement point instead of relying only on convention.

The tradeoff is that the first version is intentionally lightweight. It does not fully parse Swift syntax and it does not prove every possible forbidden reference. That is acceptable because it still catches the most likely and most damaging boundary violations with low maintenance cost.

Later versions of the architecture tests expanded beyond this initial rule set. The active test suite now also covers additional layer and folder-structure constraints where practical, while this ADR records the first enforcement step.
