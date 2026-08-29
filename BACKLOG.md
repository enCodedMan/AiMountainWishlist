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

M0 is otherwise complete. Blocked on the founder for: (1) verifying the
scaffold on a Mac, (2) creating the real Supabase project so `app-engineer`
can wire up live auth/data for M1, (3) Apple Developer Program enrollment
for device testing (not urgent — Simulator covers early M1 work).

# NOW

- Charts/Analytics screen wireframe (flagged as out of scope by the
  Profile pass — needed before `app-engineer` builds it)
- Quest chain metadata schema gap: nothing currently stores a chain's own
  display name/description (e.g. "5K Questline") — `docs/wireframes.md`'s
  achievement-detail screen already assumes this exists ("Part of the 5K
  Questline · Step 3 of 6"). Small migration addition, surfaced while
  writing seed content — needed before that part of achievement detail
  can be built.

# NEXT

- Authentication (blocked on founder's Supabase project)
- User profile
- Achievement library (decode/import `achievements.v1.json` once a real
  Supabase project exists)
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
