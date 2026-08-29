# Life Achievement App

An iPhone-first app that turns real life into a satisfying achievement and
progression system: Xbox/Steam-style achievements + RPG progression + a
personal life dashboard. "The phone is the scoreboard; the real game
happens outside the app."

Full product philosophy, mechanics, and the mandatory pre-feature Product
Test: **`docs/product-constitution.md`**. Read it before any product or
scope decision. It is the tiebreaker whenever this file and a request seem
to conflict.

## Stack decisions (made with the founder)

- **Client:** Native iOS, Swift + SwiftUI, MVVM. Chosen over
  React Native/Flutter to hit the native-feel, animation, and haptics bar
  the constitution sets for the achievement-unlock experience. Android is
  explicitly a later, separate native effort — keep business logic in a
  thin layer that isn't gratuitously SwiftUI-coupled, but don't build
  cross-platform abstractions prematurely.
- **Backend:** Supabase (Postgres + Auth + Storage + Realtime). Chosen
  over a custom backend because it gets a pre-launch product to "actually
  works" fastest, and over Firebase because the data (leaderboards,
  rarity %, category aggregates, quest chains) is relational and Postgres
  row-level security maps cleanly onto "users control what's public" /
  friends-only visibility.
- These are the only two infra decisions made in advance. Everything else
  (specific libraries, folder structure, table names) is normal
  engineering judgment — decide it, don't ask.

## Working agreements

- The founder is the Product Owner. Agents make implementation calls
  independently but escalate anything that materially changes UX,
  monetization, privacy, or product direction — see
  `docs/product-constitution.md` → Development Philosophy.
- Before building any significant new feature or mechanic, run it through
  the Product Test in `docs/product-constitution.md` (the
  `product-guardian` subagent exists specifically for this — use it).
- Never implement: XP purchases, pay-to-win progression, streak-shame
  mechanics, paid goal/quest slots, or dark patterns of any kind. These
  are hard constraints, not style preferences.
- We are pre-launch with a handful of users, not millions. Don't build
  infrastructure or abstractions for scale we don't have.

## Subagents available in `.claude/agents/`

- **product-guardian** — gate-checks features/mechanics against the
  Product Test and philosophy; flags what needs founder sign-off.
- **ios-engineer** — SwiftUI screens, view models, navigation, local
  state.
- **backend-architect** — Supabase schema, RLS policies, API surface.
- **game-designer** — achievement library content, quest chains, XP
  values, categories, rarity, secret achievements.
- **motion-designer** — the achievement-unlock celebration, onboarding
  feel, animation/haptics spec.

Reach for the specialized subagent when a task is squarely in its lane
instead of doing it inline.
