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
