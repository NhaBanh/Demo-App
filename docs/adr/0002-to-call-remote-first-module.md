# ADR 0002: Keep To Call as a Remote-First Module

## Context

`To Call` was introduced as a web API-backed feature in the assignment, so the project needed a simple decision on whether to keep it remote-first or add local persistence from the start.

## Decision

Keep `To Call` remote-first and do not introduce local persistence for its main data flow.

## Consequences

This keeps `To Call` aligned with the assignment brief and avoids unnecessary persistence complexity. It also leaves `SQLite` focused on the sell and sync flows where it matters most.
