# DONE (M0)

- Product specification v0.1 — `CLAUDE.md`, `docs/product-constitution.md`
- Technical architecture — `docs/architecture.md`
- Achievement domain model — `docs/domain-model.md`
- XP/level model — `docs/domain-model.md`
- Wireframe onboarding — `docs/wireframes.md`
- Wireframe home — `docs/wireframes.md`
- Wireframe achievement detail — `docs/wireframes.md`
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

- Profile screen wireframe (flagged as out of scope by
  `docs/wireframes.md`'s M0 pass — needed before Profile is built)
- Expand seed achievement library content beyond the ~35 worked examples
  in `docs/domain-model.md` §3.2, toward a real MVP-sized built-in
  library across the six seeded categories

# NEXT

- Authentication (blocked on founder's Supabase project)
- User profile
- Achievement library (schema/seed-loading, once library content exists)
- Quest creation
- Achievement completion
- XP calculations
- Category levels

# LATER

- Friends
- Leaderboards
- Strava
- Apple Health
- AI
- Premium
- Android
