# Technical Architecture

Status: **proposed** — not yet implemented. See `BACKLOG.md` NOW section.

This is the lead-engineer's recommendation for the simplest architecture
that supports the product as described in `docs/product-constitution.md`,
given: a solo nontechnical founder, development primarily by Claude
agents, iPhone first with Android planned later, accounts and cloud sync,
a potentially large achievement library, friends/leaderboards, future
Strava/Health integrations, and optional future AI features — without
building for a scale we don't have.

## Stack (already decided — see `CLAUDE.md`)

- **Client:** Native iOS, Swift + SwiftUI, MVVM.
- **Backend:** Supabase (Postgres + Auth + Storage + Realtime).

This still holds up against the new context. Supabase specifically buys:
accounts + cloud sync (Auth), a relational store that leaderboards/rarity/
category aggregates need (Postgres), file storage for achievement evidence
photos (Storage), and a straightforward place to add AI features later
(a Supabase Edge Function calling out to an LLM) without new infrastructure.
None of that requires the founder to run a server.

## Repository layout (single repo, monorepo-style)

One repo, not one-repo-per-agent-or-component — a solo founder and a
handful of agents don't benefit from multi-repo overhead.

```
/
├── CLAUDE.md, PRODUCT_DECISIONS.md, BACKLOG.md
├── docs/
│   ├── product-constitution.md
│   └── architecture.md              (this file)
├── .claude/agents/                  (the five specialists + lead-engineer)
├── app/
│   ├── LifeAchievementApp.xcodeproj
│   ├── LifeAchievementApp/          (SwiftUI views, view models, app entry)
│   └── LifeAchievementCore/         (local Swift Package: pure domain logic)
│       ├── Sources/
│       └── Tests/
├── backend/
│   └── supabase/
│       ├── migrations/              (versioned SQL schema)
│       ├── seed/                    (achievement library seed data)
│       └── config.toml
└── .github/workflows/                (CI: run Core package tests on push)
```

**Why a separate `LifeAchievementCore` package:** XP/level math and
achievement-completion/quest-chain-progression rules must be deterministic
and unit-testable (a hard requirement from `app-engineer`'s brief). Pulling
that logic out of SwiftUI views into a plain-Swift package makes it
trivially testable, keeps progression logic from leaking into UI code, and
— as a side effect — gives a future Android port a clean, already-tested
spec to translate instead of reverse-engineering business rules out of
view code. It is not a cross-platform code-sharing layer; Android will
still be a separate native effort later.

## Data model direction

To be finalized by `product-designer` + `app-engineer` together as the
"Achievement domain model" and "XP/level model" backlog items, but the
shape is: achievement catalog (built-in / user-created / AI-generated),
per-user achievement state (not discovered → discovered → interested →
active → completed → paused → abandoned, never deleted by a state
transition), an append-only XP ledger (not a mutable counter, so lifetime
totals stay auditable and season resets never touch it), quest chains,
categories + derived category levels, user-scoped stats + personal
records, friendships + trophy case with per-field visibility, and
season-scoped leaderboard tables. Rarity is computed from real completion
aggregates, never hardcoded.

## What we deliberately are NOT building yet

- Offline-first sync with conflict resolution — Supabase is the single
  source of truth; simple last-write-wins is enough at this scale.
- Multiple environments (staging/prod) — one shared dev project until
  we're close to public release.
- A custom analytics pipeline — defer until there's a real question only
  one would answer.
- Edge functions / AI infrastructure — nothing calls an LLM yet; add it
  when a specific AI feature is greenlit.
- Any server we operate ourselves — Supabase remains managed infra.

## Testing & CI

- `LifeAchievementCore` gets XCTest coverage for XP calculation, level
  calculation, achievement completion, and quest-chain progression from
  the start — this is the one non-negotiable per `app-engineer`'s brief.
- GitHub Actions runs `swift test` on every push once the package exists.
- Backend correctness (leaderboard calculation, rarity, RLS policies)
  gets manual verification via the Supabase CLI's local dev stack for
  now; revisit automated backend tests once those systems exist.

## Milestones

**M0 — Foundation** (BACKLOG "NOW," in dependency order):

1. Architecture agreed (this document) + two founder inputs resolved
   (see below).
2. `product-designer` + `app-engineer` define the achievement domain
   model and XP/level model as a written spec.
3. `app-engineer` scaffolds the repo: Xcode project, `LifeAchievementCore`
   package with the domain types and unit tests, first Supabase migration
   matching the spec, CI running tests.
4. `ux-ui-designer` produces onboarding, home, and achievement-detail
   screen specs (the three wireframes in BACKLOG "NOW").

**M1 — Usable single-player MVP** (start of BACKLOG "NEXT"): auth,
profile, seeded achievement library, quest creation, achievement
completion, XP calculation, category levels — something the founder can
install on their own phone and actually use, before any social,
integration, or AI feature exists.

Everything else in BACKLOG "NEXT"/"LATER" follows after M1 is real and
used.

## Founder inputs this milestone needed — resolved

- App working name / bundle id, and MVP sign-in method scope — see
  PD-004 and PD-005 in `PRODUCT_DECISIONS.md`.
- Still outstanding, and only the founder can do these: create an Apple
  Developer Program account (needed for device testing and eventual App
  Store release) and create a Supabase project (needed before
  app-engineer can wire up real auth/data — schema and app scaffolding
  can proceed without it).
