# Trianglobe

Daily geography puzzle — find 5 cities on a 3D globe from one trivia question.
Spring Boot 3 / Java 21 backend, React + TypeScript + Vite frontend.
The full spec is in `docs/SPEC.md` — read it before planning any feature work.
This is a portfolio project: backend quality is the point, not feature count.

## Architecture rules

- **Server-authoritative.** Target coordinates, names, and ranks must never appear in any client-facing response until the target is confirmed or the session is finished. Check every new endpoint and DTO against this.
- **Game rules live in the aggregate.** `PlaySession` is the aggregate root and enforces all invariants (guess budget, no guesses after completion, matching against unfound targets only). If a service method contains an `if` about game rules, it is in the wrong place — move it into the aggregate.
- **Value objects** (`GeoPoint`, `Distance`, `Score`) are immutable.
- **Packages by domain, not by layer:** `game`, `content`, `player`, `stats`. Never create top-level `controller`/`service`/`repository` packages.
- **Boring over clever.** No new dependencies or infrastructure without explicit justification. Deliberately excluded already: PostGIS, Redis, CQRS, event sourcing.

## Workflow rules

- **Test-first for domain code:** write the failing JUnit test before implementing any rule in the `game` package.
- Integration tests use **Testcontainers with real Postgres — never H2**.
- Every schema change is a **new Flyway migration**; never edit an applied migration.
- All tunables (scoring constants, default bullseye radius, guess budget) are **named constants or config properties** — no inline magic numbers.
- **Conventional commits:** `feat:`, `fix:`, `test:`, `refactor:`, `chore:`.
- **Milestone discipline:** only work on the current milestone (`docs/SPEC.md` §9). Park out-of-scope ideas in `BACKLOG.md` instead of implementing them.

## Learning workflow

This project doubles as interview preparation — Lukas must be able to defend every design decision.

- **Explain-back:** at the end of each working session, ask Lukas 2–3 comprehension questions about the code written in that session (why, not just what). If he can't answer one, note the topic as the starting point for the next session.
- **ADRs:** when a decision has alternatives worth naming (library choice, pattern, trade-off), write a short ADR to `docs/adr/NNN-title.md` — 3–5 sentences: context, decision, why, what was rejected. Existing decisions worth backfilling as ADRs: server-authoritative scoring, no PostGIS, Caffeine over Redis, anonymous-JWT design.

## Commands

<!-- Fill in after M0 scaffolding -->
- Backend build + all tests: `./mvnw verify`
- Frontend dev / tests: `npm run dev` / `npm test`
- Local stack: `docker compose up`
