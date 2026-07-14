# Trianglobe — Project Specification (v1)

*Find the five. Solve the sphere.*

*Step 5 of the planning process. Consolidated 2026-07-14. Feeds Plan Mode in the Code tab.*

---

## 1. Vision

A daily geography puzzle. One trivia question defines a ranked set of 5 hidden city targets
("Locate the top 5 largest French-speaking cities"). The player taps a 3D globe: a tap within
the bullseye radius of a target confirms it instantly, with its rank revealed ("Paris is
correct — place 2 of 5!"). A miss consumes a guess and returns the distance to the closest
*unfound* target, turning each round into a triangulation hunt. 8 guesses, 5 targets, one
puzzle per day, 2–3 minute sessions.

**Lineage / differentiation** (verified 2026-07-14 — no existing game combines all three):
Globle's distance-feedback loop meets Sporcle's question-defined list trivia on MapTap's 3D
globe. The "distance to closest remaining target" multi-target hunt has no direct precedent
in the daily-geography genre.

**Primary purpose:** portfolio project demonstrating production-grade Java/Spring Boot
backend engineering (see §10, Recruiter Evidence Map). Playability is the hook; the backend
is the point.

## 2. Game Mechanics (locked)

- One puzzle per day; day boundary is midnight **Europe/Berlin**. One attempt per player per puzzle.
- Question defines **5 ranked targets** (v1: cities only; data model uses generic named points for later expansion to countries, rivers, landmarks).
- **8 guesses** for 5 targets (golf-style). Session ends when all targets are found or guesses run out.
- **Hit:** tap within bullseye radius (default 50 km, tunable per puzzle) of an unfound target → instant confirmation + name + rank reveal.
- **Miss:** guess consumed; feedback = great-circle distance to the closest **unfound** target. No direction, no identity.
- **End reveal:** all targets shown on the globe with the player's taps, per-target results, total score, and a Wordle-style emoji share text.
- **Scoring v1 (tunable constants, refine via playtesting):** found target = 100 pts; unused guess = +25 pts; unfound target = 0. Max 575.
- Questions are **manually authored** by the maintainer, each with a source note and an "as of" date to guarantee unambiguity (e.g. city proper vs. metro is fixed per question).

**Parked (post-v1 backlog):** puzzle archive, leaderboards, rarity-weighted scoring, DE/EN
i18n, non-city target types, "hidden theme" weekly special mode, multiplayer.

## 3. Scope (MoSCoW)

**Must (v1):**

- Daily puzzle loop as specified in §2, fully server-authoritative
- Anonymous play via device-ID JWT; optional account upgrade (email + password) syncing streaks/stats across devices
- Personal stats: streak, history of past results
- Global stats after completion: "you beat 78% of today's players", per-target find rate (cached)
- Admin area (ROLE_ADMIN): CRUD for puzzles/targets, publish calendar, scheduled daily activation
- Emoji share text
- Quality baseline: unit + integration tests, CI, OpenAPI docs, Dockerized, deployed and publicly linkable

**Should:** end-reveal animation polish, mobile-friendly globe interaction tuning.

**Could:** anything in the parked list above.

**Won't (v1):** multiplayer/real-time, native mobile apps, user-generated content, practice mode.

## 4. Tech Stack

| Layer | Choice | Rationale |
|---|---|---|
| Language | Java 21 (LTS) | Regional job-posting keyword #1 |
| Framework | Spring Boot 3.x — Web, Data JPA, Security, Validation, `@Scheduled` | The stack this project exists to prove |
| Build | Maven | Most common in German enterprise |
| DB | PostgreSQL + Flyway migrations | Standard pairing; migration discipline is CV-relevant |
| Geo math | Haversine as pure functions in the domain | Deliberately **no PostGIS** — 5 targets/day doesn't justify it; documented as an architecture decision |
| Auth | Spring Security + JWT (anonymous device principal, optional account upgrade) | One pipeline for both identity levels |
| Caching | Caffeine (in-process) for daily aggregate stats | Right-sized; Redis would be résumé-driven overkill |
| Tests | JUnit 5, Mockito, Testcontainers (real Postgres), MockMvc | Testcontainers signals professional practice |
| API docs | springdoc-openapi | Swagger UI for free |
| Frontend | React + TypeScript + Vite + Tailwind, react-globe.gl | Existing strength; globe is the visual showcase |
| Frontend tests | Vitest + Testing Library | Standard for the stack |
| CI/CD | GitHub Actions: build, test, lint, Docker image | |
| Deploy | AWS via Terraform (single small instance or Fargate + RDS) | Makes AWS/Terraform CV claims linkable |
| Local dev | Docker Compose (Postgres + app) | |

## 5. Architecture

**Server-authoritative by design.** Answer coordinates, identities, and ranks never reach the
client until confirmed or the session ends. The client sends tap coordinates; the server
evaluates. Rationale (README-worthy): keeps global stats meaningful, keeps all game rules in
one tested place, and is the foundation of the domain model below. Tap/globe interactions
remain fully client-side; the guess round-trip (~50–100 ms) is masked by the tap animation.

**DDD-lite.** Core tactical DDD without heavyweight ceremony (no CQRS, no event sourcing, no
multi-module bounded contexts):

- **Aggregate root: `PlaySession`.** Owns its `Guess` list and enforces every invariant: guess budget, no guesses after completion, matching only against unfound targets, one session per player per puzzle. The entire game rule set runs through `session.submitGuess(GeoPoint): GuessResult`.
- **Value objects:** `GeoPoint`, `Distance`, `Score`, `BullseyeRadius`.
- **Domain services:** pure scoring/distance functions (Haversine, closest-unfound-target).
- **Thin application services:** load aggregate → delegate → save. Controllers and repositories are plumbing.
- **Packages by domain, not by layer:** `game`, `content` (puzzles + admin), `player` (identity), `stats`.

**Anemic-model check:** if a service method contains an `if` about game rules, the rule is in
the wrong place — move it into the aggregate.

## 6. Data Model

```
puzzle        id, date (unique), question_text, source_note, as_of_date,
              bullseye_radius_km, status (DRAFT|SCHEDULED|PUBLISHED)
target        id, puzzle_id FK, name, lat, lng, rank (1–5)
              — generic named point; "city" is content, not schema
player        id, device_id (unique), created_at
account       id, player_id FK (1:1, optional), email (unique),
              password_hash, role (USER|ADMIN)
play_session  id, player_id FK, puzzle_id FK (unique together),
              started_at, completed_at, guesses_used, score
guess         id, session_id FK, seq, lat, lng,
              matched_target_id FK (nullable), distance_km
```

Daily aggregate stats are computed by query over completed sessions and cached (Caffeine,
TTL a few minutes) — no denormalized stats table in v1.

## 7. API Contract (sketch)

```
POST /api/sessions                    → start today's session: question text, guess budget,
                                        bullseye radius. NO coordinates.
POST /api/sessions/{id}/guesses       body {lat, lng} →
                                        HIT  {target name, rank, points, remaining}
                                      | MISS {distanceKm to closest unfound, remaining}
GET  /api/sessions/{id}/result        → full reveal + score breakdown (only when finished)
GET  /api/puzzles/today/stats         → percentile, find rates (only after completion; cached)
GET  /api/players/me                  → streak, history

POST /api/auth/anonymous              → device-ID JWT on first visit
POST /api/auth/register | /login      → upgrade to / authenticate account (same player id)

/api/admin/puzzles (CRUD)             → ROLE_ADMIN; publish calendar;
                                        @Scheduled job activates the day's puzzle at 00:00 Berlin
```

Errors: RFC 7807 problem+json. Validation via Bean Validation. Rate limit on the guess
endpoint (simple bucket per session).

## 8. Testing Strategy

- **Domain unit tests (the bulk):** `PlaySession` invariants, matching, Haversine accuracy against known city pairs, scoring, edge cases (two targets within one bullseye, antimeridian, poles).
- **Integration:** Testcontainers Postgres — repository mappings, Flyway migrations, the one-attempt-per-day constraint.
- **API:** MockMvc — auth flows (anonymous → upgrade), admin authorization, guess flow happy/error paths.
- **Frontend:** Vitest smoke + logic tests; globe rendering tested manually.
- CI gates every PR on the full suite.

## 9. Milestones (~6 weeks part-time)

- **M0 — Walking skeleton (days):** repo, Spring Boot + React scaffold, Docker Compose, CI pipeline, health endpoint deployed to AWS via Terraform. *Deploy first, features second.*
- **M1 — Domain core (w1–2):** puzzle/target schema + Flyway, `PlaySession` aggregate, guess endpoint, full domain test suite. Playable via Swagger UI.
- **M2 — Globe frontend (w2–3):** react-globe.gl play flow, hit/miss feedback, end reveal, share text. First real playtest → tune scoring constants.
- **M3 — Identity (w4):** anonymous JWT, account upgrade, streaks + history.
- **M4 — Content & admin (w5):** admin CRUD + publish calendar + scheduled activation; author ~30 launch puzzles with source notes.
- **M5 — Stats & polish (w6):** global stats + caching, README with architecture decisions, deployment hardening, public link.

Each milestone ends deployed and demonstrable. If time runs short, M5's stats can slip to
v1.1 — nothing else can.

## 10. Recruiter Evidence Map

| Job-posting requirement | Where this project proves it |
|---|---|
| Java / Spring Boot | Entire backend; Spring Web, Data JPA, Security, Validation, Scheduling |
| DDD | `PlaySession` aggregate root, value objects, domain-package structure — defensible in interview |
| SQL / data modeling | 6-entity schema, constraints, aggregate queries, Flyway |
| Security / auth | JWT pipeline with anonymous principals + role-based admin |
| Testing / TDD | Domain-first test suite, Testcontainers, CI gate |
| REST API design | Versionable contract, problem+json, OpenAPI |
| Docker / CI/CD | Compose, GitHub Actions, image build |
| AWS / Terraform | Live deployment, IaC in repo |
| Frontend (existing strength) | 3D globe UX — the demo that makes reviewers keep reading |

## 11. Open Items

- Scoring constants — tune after M2 playtest.
- Launch content — 30 authored puzzles needed by M4.

## 12. Next Steps (process steps 6–8)

1. Create GitHub repo `trianglobe` (public); copy this spec into it as `docs/SPEC.md`.
2. Code tab, Plan Mode against this spec, starting with M0.
3. Write `CLAUDE.md`: package-by-domain convention, "rules live in the aggregate" rule, test-first for domain code, conventional commits, constants for all tunables.
4. Build in milestone-sized chunks; replan at each milestone boundary.
