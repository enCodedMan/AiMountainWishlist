# Life Achievement App

An iPhone-first app that turns real life into a satisfying achievement and
progression system: Xbox/Steam-style achievements + RPG progression + a
personal life dashboard. "The phone is the scoreboard; the real game
happens outside the app."

Full product philosophy, mechanics, and the mandatory pre-feature Product
Test: **`docs/product-constitution.md`**. Read it before any product or
scope decision. It is the tiebreaker whenever this file and a request seem
to conflict. Settled decisions live in **`PRODUCT_DECISIONS.md`** (check
before re-deciding something). Current work lives in **`BACKLOG.md`**
(NOW / NEXT / LATER).

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
  `product-designer` subagent exists specifically for this — use it).
- Never implement: XP purchases, pay-to-win progression, streak-shame
  mechanics, paid goal/quest slots, or dark patterns of any kind. These
  are hard constraints, not style preferences.
- We are pre-launch with a handful of users, not millions. Don't build
  infrastructure or abstractions for scale we don't have.

## Subagents available in `.claude/agents/`

- **lead-engineer** — default entry point for anything non-trivial: plans
  the work, delegates narrowly-scoped tasks to the specialists below,
  reviews their output, and integrates it. Route cross-cutting or
  ambiguous-scope work here first.
- **product-designer** — core gameplay loop, achievement taxonomy, quest
  system/chains, XP/levels/rarity, discovery, onboarding progression,
  secret achievements; gate-checks mechanics against the Product Test.
- **ux-ui-designer** — information architecture, navigation, screen and
  flow design, achievement-unlock presentation, animation/haptic intent,
  accessibility, visual consistency.
- **app-engineer** — implements the SwiftUI client and Supabase backend:
  screens, view models, schema, RLS, sync, tests.
- **qa-critic** — independent adversarial testing and product criticism;
  finds bugs, exploits, and constitution violations before users do.
- **monetization-growth** — pricing, premium features, conversion/
  retention strategy, sanity-checked against user trust.

For a small task squarely inside one specialist's lane with no
cross-cutting risk, go straight to that specialist instead of routing
through lead-engineer.
