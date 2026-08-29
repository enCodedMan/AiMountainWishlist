# DONE (M0)

- Product specification v0.1 — `CLAUDE.md`, `docs/product-constitution.md`
- Technical architecture — `docs/architecture.md`
- Achievement domain model — `docs/domain-model.md`
- XP/level model — `docs/domain-model.md`
- Wireframe onboarding — `docs/wireframes.md`
- Wireframe home — `docs/wireframes.md`
- Wireframe achievement detail — `docs/wireframes.md`
- Wireframe profile — `docs/wireframes.md` (flags a founder decision:
  confirm deferring the profile public/private toggle to post-Friends,
  structural DB field only for now, is right — see doc §4f)
- Wireframe Charts & Analytics — `docs/wireframes.md` §5 (single
  continuous scroll + sticky range/jump controls, not tabs; Friend
  Comparison hidden entirely at MVP rather than shown empty, since
  Friends has zero presence anywhere in the app yet — see doc §5b, flagged
  for founder confirmation. Personal Record History and Seasonal
  Comparisons ship as honest "Coming soon" cards, blocked on
  `product-designer` schema work — see doc §5c — the rest of the screen's
  sections build from data `domain-model.md` already specifies)
- Seed achievement library v1 — `backend/supabase/seed/achievements.v1.json`
  (107 built-in achievements), `docs/seed-achievements.md`. Not yet
  loaded into any database (no Supabase project exists yet) or decoded
  by app-engineer's seed-loading code — that's the NEXT "Achievement
  library" item below.
- Repo scaffold — `app/LifeAchievementCore` (domain types + XCTest
  coverage), `app/project.yml` (XcodeGen), first Supabase migration at
  `backend/supabase/migrations/`. **Written but unverified** — no
  Swift/Xcode toolchain has run `swift test` or built the Xcode project
  yet; needs a Mac before M0 is actually done, not just drafted.
- Quest chain metadata — `quest_chains` table added to
  `backend/supabase/migrations/20260829000000_initial_schema.sql` (name/
  description/category per chain, FK'd from `achievement_definitions
  .quest_chain_id` on delete restrict), `QuestChainDefinition` Swift type
  in `app/LifeAchievementCore/Sources/LifeAchievementCore/QuestChain.swift`,
  seed rows for the three real MVP chains in
  `backend/supabase/seed/quest_chains.v1.json`. Same unverified caveat as
  the rest of the scaffold above — no Swift/Xcode toolchain has run this.
- Stats & Seasons domain model — `docs/domain-model.md` §8 (`Stat`/
  `StatEntry` entities, live-derived personal records and record-broken
  events, no new stored event table) and §9 (Seasons defined as fixed
  Gregorian calendar quarters, not named seasons; no stored `Season`
  entity; no mutable season-score table — everything the Charts screen
  needs is computed on demand from existing timestamped data). This
  closes the two schema gaps `ux-ui-designer` flagged in
  `docs/wireframes.md` §5a #9/#10 and §5c while designing Charts &
  Analytics. Not yet implemented as actual Postgres tables/Swift types —
  that's `app-engineer` work, same blocker as the rest of the schema (no
  Supabase project exists yet). `docs/wireframes.md` §5a #9/#10, §5c, and
  Open Questions #9 updated to reflect this is no longer blocked on
  product design, only on database existence and (for Personal Record
  History specifically) a dedicated `ux-ui-designer` screen-layout pass.
- Personal Record History screen design — `docs/wireframes.md` §5d/§5e:
  inline Personal Records card, all-stats list, per-stat drill-in with
  record-broken markers (normalized so "improvement" always reads as
  "up" regardless of a stat's comparison direction), and the create/
  log/edit/delete flows — including the one deliberate divergence from
  this doc's "history is permanent" pattern, since `StatEntry` is
  user-editable/deletable. No further design work remains for this
  screen; only the live database is missing.

**This closes every M0/M0-follow-up item reachable without the
founder's accounts.** Everything below in NEXT needs the real Supabase
project (and, separately, a Mac to actually verify anything already
written).

M0 is otherwise complete. Blocked on the founder for: (1) verifying the
scaffold on a Mac, (2) creating the real Supabase project so `app-engineer`
can wire up live auth/data for M1, (3) Apple Developer Program enrollment
for device testing (not urgent — Simulator covers early M1 work).

# NOW

(empty — both items that were here have moved to DONE above)

# NEXT

- Authentication (blocked on founder's Supabase project)
- User profile
- Achievement library (decode/import `achievements.v1.json` and
  `quest_chains.v1.json` once a real Supabase project exists)
- Quest creation
- Achievement completion
- XP calculations
- Category levels
- Stats & Personal Records, Seasonal Comparisons (Charts screen): fully
  speced end-to-end (`docs/domain-model.md` §8/§9, `docs/wireframes.md`
  §5d/§5e) — implementable as soon as the founder's real Supabase
  project exists (same blocker as Authentication above). No remaining
  design work.
- Meta-achievement evaluator: new engineering scope (not a
  `CompletionCriteria` extension) to support the 6 secret achievements
  proposed in `docs/seed-achievements.md` §5 — each depends on a user's
  full achievement/category state, not a single stat. Not urgent; secrets
  aren't core-loop-critical for an MVP.

# LATER

- Friends
- Leaderboards
- Strava
- Apple Health
- AI
- Premium
- Android
