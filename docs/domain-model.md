# Achievement & XP/Level Domain Model — v0.1

Status: **proposed spec** — written for `app-engineer` to implement directly
as Swift types in `LifeAchievementCore` (per `docs/architecture.md`, M0 step 2).
Authoritative sources this spec must stay consistent with:
`docs/product-constitution.md` (tiebreaker on any conflict) and
`PRODUCT_DECISIONS.md`. Where this document makes a scoping call the
constitution left open, that call is flagged explicitly rather than
implied.

Anywhere this doc is ambiguous, that ambiguity is a bug in the doc — flag
it back to `product-designer` rather than guessing silently.

---

## 0. Two-part model: definition vs. per-user instance

The constitution lists one flat set of "Achievement" fields, but two of
those fields (verification level, state) are not properties of the
*achievement itself* — they're properties of *one user's relationship* to
it. Modeling this as one entity would force a `verificationLevel` field to
exist on achievements no one has completed yet, which is meaningless.
Split into two types:

- **`AchievementDefinition`** — the catalog entry. One row exists
  regardless of how many users have seen or completed it. Built-in
  achievements are seeded once; user-created and AI-generated achievements
  create one definition per creation event (see §1.2 note on ownership).
- **`UserAchievementInstance`** — one row per (user, achievement
  definition) pair, created lazily (see §1.5). Holds the state-machine
  state, verification level actually achieved, quest-slot assignment, and
  timestamps.

This split is the resolution to the ambiguity the task flagged around
"verification level" living on the Achievement entity — it doesn't; it
lives on the instance. `app-engineer`: model these as two Swift types /
two Postgres tables, not one.

---

## 1. Entity shapes

### 1.1 `AchievementDefinition`

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `name` | String | |
| `category` | `Category` enum (§2) | Exactly one primary category. No multi-category tagging in v0.1 — see §2 note on the `general` pseudo-category for cross-category secrets. |
| `description` | String | |
| `completionCriteria` | `CompletionCriteria` (§1.3) | |
| `xpValue` | Int | From the fixed discrete bands in §3.1, never an arbitrary number. |
| `questChainId` | UUID? | Null if standalone. |
| `questChainPosition` | Int? | 1-indexed rung position within the chain. Null if standalone. |
| `provisionalRarity` | `RarityLabel` enum? | Design-time-only placeholder for seed content (§5). Null for user-created (they don't get a curated rarity guess). Never confused with computed rarity, which is a separate aggregate (§5). |
| `isSecret` | Bool | If true, name/description/criteria are hidden from browse/discovery surfaces until unlocked or nearly met — presentation detail for `ux-ui-designer`, but the flag itself lives here. |
| `source` | `Source` enum: `builtIn`, `userCreated`, `aiGenerated`, `integrationDetected` | |
| `creatorUserId` | UUID? | Set for `userCreated`; null otherwise. Determines who can edit/delete the definition. |
| `createdAt` | Timestamp | |

### 1.2 `UserAchievementInstance`

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | |
| `userId` | UUID | |
| `achievementDefinitionId` | UUID | |
| `state` | `AchievementState` enum (§1.4) | |
| `questSlotType` | `QuestSlotType` enum: `none`, `main`, `side` | Meaningful only while `state ∈ {active, paused}`; see §6. |
| `verificationLevel` | `VerificationLevel` enum: `selfReported`, `evidence`, `verified` | Set at completion time; defaults to `selfReported`. |
| `evidenceRef` | Storage URL? | Populated when `verificationLevel = evidence`. |
| `progressValue` | Double? | Current measured progress toward `completionCriteria.targetValue`, for `cumulativeCount`/`thresholdRecord` types. Null for `binary`. |
| `isHiddenFromProfile` | Bool | Pure visibility toggle — see §1.4 note on "removal." Never affects XP or state. |
| `discoveredAt` | Timestamp? | |
| `activatedAt` | Timestamp? | |
| `completedAt` | Timestamp? | |
| `xpLedgerEntryId` | UUID? | Points at the ledger entry (see §3) that granted XP for this completion, so an undo can find and reverse exactly one entry. Null unless `state = completed` (or was, before an undo). |

### 1.3 `CompletionCriteria`

Three shapes, chosen to cover the achievement types in the constitution's
own examples without inventing complexity we don't need yet:

| `type` | Meaning | Example | Fields used |
|---|---|---|---|
| `binary` | Did it happen, yes/no. | "Run your first 5K," "Skydive," "Graduate college" | none beyond type |
| `cumulativeCount` | Reach N occurrences, no deadline. | "Visit 10 countries," "Summit five different 14ers" | `targetValue: Double`, `unit: String` |
| `thresholdRecord` | A measured personal-record-style value crosses a bound. | "Sub-20 5K" (time ≤ 20:00), "Bench press 185 lb" (weight ≥ 185) | `targetValue: Double`, `unit: String`, `comparisonDirection: atLeast \| atMost` |

Known edge case, deliberately deferred: some real thresholds are relative
to another user stat rather than a fixed number (e.g., "bench your own
bodyweight"). Implementing that requires the completion criteria to read
a live user stat at evaluation time. v0.1 seed content avoids
stat-relative thresholds (use fixed tiers like "bench 135 lb" / "bench
185 lb" instead); revisit once stats (BACKLOG NEXT) exist and there's a
concrete need.

### 1.4 State machine

States: `notDiscovered`, `discovered`, `interested`, `active`,
`completed`, `paused`, `abandoned`.

**Implementation note:** `notDiscovered` has no database row. It's the
default, implicit state for any built-in/AI-generated `AchievementDefinition`
with no `UserAchievementInstance` row yet for that user. Do **not** create
a row per user per catalog item up front — that's an unbounded row count
for no benefit. Create the row the moment a real discovery event happens
(the achievement's detail screen is opened, it's presented in onboarding,
or a recommendation is explicitly surfaced) — not merely because the item
rendered in a scrollable list.

**Transition table:**

| From | To | Trigger | Notes |
|---|---|---|---|
| `notDiscovered` | `discovered` | User opens detail view, sees it in onboarding, or a recommendation is surfaced | Creates the row |
| `discovered` | `interested` | "Want to do" / save to backlog | |
| `discovered` | `active` | "Start" directly, or onboarding marks an in-progress goal | Subject to quest-slot caps (§6) |
| `discovered` | `completed` | "Done" (onboarding retro-credit, or "I already did this") | Grants XP immediately |
| `discovered` | `abandoned` | "Not interested" | Reversible, not punitive — see below |
| `interested` | `active` | Commit from backlog | Subject to quest-slot caps |
| `interested` | `abandoned` | Remove from backlog | |
| `interested` | `completed` | Mark done directly from backlog | Rare but valid path (user realizes they already did it) |
| `active` | `completed` | Criteria met, user confirms | Grants XP, frees quest slot, may unlock next chain rung (§4.4) |
| `active` | `paused` | User pauses | Frees the quest slot immediately — paused quests never count against the 3/5 caps |
| `active` | `abandoned` | User stops pursuing | Frees the quest slot. No XP to lose, no penalty |
| `active` | `interested` | Demote back to backlog without fully abandoning | Frees the quest slot |
| `paused` | `active` | Resume | Slot caps re-checked at resume time (§6) |
| `paused` | `abandoned` | Give up while paused | |
| `paused` | `completed` | User finishes while nominally paused | Edge case, allowed — status just hadn't been updated |
| `abandoned` | `interested` | Reconsider ("maybe someday") | Fully reversible |
| `abandoned` | `active` | Restart directly | Subject to quest-slot caps |
| `completed` | `discovered` | Explicit "Undo completion" only | See below — this is a correction path, not gameplay |

`completed` is otherwise terminal — no automatic transitions leave it.

**Onboarding's "Not interested" maps to `abandoned`.** This is a naming
choice worth flagging: "abandoned" reads harshly for something a user
never even started. The *state* is fine (it's reversible, non-punitive,
and just means "not currently in view") — but `ux-ui-designer` should
never surface the word "Abandoned" as UI copy for this path; user-facing
copy should read like "Not for me" / "Hide," while the underlying state
value stays `abandoned` for engine simplicity (one state, two possible
entry triggers, rather than an 8th state).

**Undo completion vs. hide/removal — two different actions, don't
conflate them:**

- **Hide from profile** (`isHiddenFromProfile = true`): pure visibility
  toggle. State stays `completed`, XP is untouched. This is what "control
  what's public" (constitution's social philosophy) means — a completed
  achievement stays permanently in the user's private history and its XP
  stands, it just doesn't render on the public profile/trophy case.
- **Undo completion** (`completed → discovered`): a correction path for
  "I tapped the wrong thing" / "I marked this by mistake." Requires
  confirmation copy that says XP will be removed. Reverses the exact XP
  ledger entry referenced by `xpLedgerEntryId` (see §3) rather than just
  decrementing a counter, so the ledger stays auditable. Lands back at
  `discovered`, not `active` — undoing a mistaken completion means "this
  didn't happen," not "I'm now pursuing it."

**Special-cased non-linear transitions worth calling out explicitly so
the state machine isn't hard-coded to assume a strict left-to-right
flow:**

- **User-created achievements** never pass through `notDiscovered` or
  `discovered` for their creator — creation writes directly into
  `interested` or `active` (creator's choice at creation time, one tap),
  consistent with "avoid a twenty-field form."
- **AI-generated** achievements (future) are created directly into
  `discovered` for the target user (they're a suggestion, not yet chosen).
- **Integration-detected** achievements (future — Strava, Health) can go
  straight from implicit `notDiscovered` to `completed` in a single step,
  skipping `discovered`/`interested`/`active` entirely, with
  `verificationLevel = verified` set automatically. Don't assume
  `active` is a required waypoint before `completed`.

---

## 2. Categories — v0.1 scope

All ten categories from the constitution exist as first-class enum values
from day one (so nothing has to migrate later): `fitness`, `adventure`,
`travel`, `money`, `career`, `education`, `skills`, `relationships`,
`makerProjects`, `experiences`. Plus one internal, non-browsable value:
`general`, for secret/meta achievements that legitimately span categories
(e.g., "complete an achievement in every category") — this keeps the
invariant that every XP-earning event has exactly one category, so
overall XP always equals the sum of category XP (see §3.3).

**Recommendation: seed real built-in content for six categories at MVP;
leave four defined-but-empty.**

**Seed at MVP:** Fitness, Adventure, Travel, Education, Skills,
Experiences.

**Defined but empty at MVP** (category exists, category levels work,
users can create their own achievements in them immediately — just no
curated built-in list yet): Money, Career, Relationships, Maker/Projects.

Reasoning:

- The six seeded categories are the ones where accomplishments are
  broadly universal (most adults have *some* history here, which matters
  for onboarding's "this already looks like my life" moment), easy to
  self-report unambiguously, and low-friction to genericize into a
  built-in library entry without being presumptuous about someone's
  circumstances.
- **Money** deferred: a good built-in library entry needs a number
  ("save $10,000"), and a flat dollar figure isn't equally meaningful
  across income levels — getting this right needs real design work
  (percentile-based framing? locale-adjusted?) that's out of scope for
  M0. Users can still self-create money goals immediately; nothing is
  broken, just not curated yet.
- **Career** deferred: titles, promotions, and "success" are so
  context-dependent (industry, seniority, geography) that a generic
  built-in list risks being either useless-vague ("get promoted") or
  presumptuous. Better to see what users actually create before curating.
- **Relationships** deferred: this is the most personally sensitive
  category (dating, marriage, family, friendship milestones). A canned
  built-in list risks reading as prescriptive or judgmental about
  someone's life choices and timeline. User-created content here should
  come from the user's own framing, not the app's suggestion.
- **Maker/Projects** deferred: extremely wide variance in what "a
  project" means (woodworking vs. software vs. cooking vs. crafts) makes
  a useful generic library hard to write well without real user-created
  examples to learn from first.

This is a reversible scoping call, not a structural one — none of the
four deferred categories require schema changes to activate later; they
just need seed data written.

---

## 3. XP model

### 3.1 Bands & design principle

XP values are drawn from a **small fixed set of discrete numbers within
each constitution band**, never an arbitrary per-item number. This keeps
the scale legible ("this is a 500-XP achievement, same tier as running a
marathon") and prevents slow, unnoticed inflation over time as more
content gets added by different people.

| Band (constitution) | Discrete v0.1 values allowed |
|---|---|
| Small experience (10–50) | 10, 15, 20, 25, 30, 40, 50 |
| Moderate achievement (100–500) | 100, 150, 200, 250, 300, 400, 500 |
| Major achievement (500–2,500) | 500, 750, 1000, 1500, 2000, 2500 |
| Exceptional lifetime achievement (2,500–10,000+) | 2500, 5000, 7500, 10000 |

Every built-in achievement's `xpValue` must be one of these numbers. This
is a hard rule for seed-content authors and for any future admin tooling,
not a suggestion.

### 3.2 Worked examples

**Fitness**

| Achievement | Criteria type | XP |
|---|---|---|
| Do your first pull-up | binary | 25 |
| Run your first 5K | binary | 50 |
| Run a sub-30 5K | thresholdRecord | 100 |
| Bench press 135 lb | thresholdRecord | 150 |
| Run a sub-25 5K | thresholdRecord | 250 |
| Complete a marathon | binary | 1000 |
| Run a sub-20 5K | thresholdRecord | 750 |
| Complete an Ironman triathlon | binary | 2500 |

**Adventure**

| Achievement | Criteria type | XP |
|---|---|---|
| Go camping for the first time | binary | 25 |
| Skydive | binary | 300 |
| Complete a 3+ night backpacking trip | binary | 200 |
| Summit your first 14er (14,000 ft) | binary | 500 |
| Summit a peak over 4,000 m | binary | 1000 |
| Summit an 8,000 m peak | binary | 5000 |

**Travel**

| Achievement | Criteria type | XP |
|---|---|---|
| Visit a new state/province | cumulativeCount | 20 |
| Visit a new country | cumulativeCount | 50 |
| Take a solo international trip | binary | 150 |
| Visit 10 countries | cumulativeCount | 500 |
| Visit all 7 continents | cumulativeCount | 2500 |
| Visit every US National Park | cumulativeCount | 5000 |

**Education**

| Achievement | Criteria type | XP |
|---|---|---|
| Read 12 books in a year | cumulativeCount | 200 |
| Graduate high school | binary | 150 |
| Become conversational in a new language | binary | 750 |
| Graduate college (bachelor's) | binary | 1500 |
| Earn a master's degree | binary | 2000 |
| Earn a PhD | binary | 5000 |

**Skills**

| Achievement | Criteria type | XP |
|---|---|---|
| Cook a meal from scratch (first time) | binary | 15 |
| Learn to play a song on an instrument | binary | 50 |
| Learn to swim | binary | 100 |
| Get a driver's license | binary | 100 |
| Perform on an instrument publicly | binary | 500 |
| Earn a professional certification (CPA/PE/PMP-tier) | binary | 1500 |

**Experiences**

| Achievement | Criteria type | XP |
|---|---|---|
| Try a new cuisine | binary | 10 |
| Attend a live concert | binary | 15 |
| Meet a personal hero | binary | 100 |
| See a total solar eclipse | binary | 100 |
| Attend a major sporting event (World Cup, Super Bowl tier) | binary | 200 |

**Forward-reference only (not seeded at MVP, given here purely so future
content for the deferred categories starts from a calibrated baseline
rather than drifting):**

| Category | Achievement | XP |
|---|---|---|
| Money | Save your first $1,000 | 100 |
| Money | Become debt-free | 750 |
| Money | Reach $100,000 net worth | 1500 |
| Career | Get your first job | 100 |
| Career | Start a business | 1000 |
| Maker/Projects | Build your first piece of furniture | 100 |
| Maker/Projects | Complete a home renovation project | 300 |

Relationships intentionally has no forward-reference examples here — per
§2, this category's content needs dedicated design work, not a quick
placeholder list, given how easily canned relationship milestones read as
prescriptive.

### 3.3 XP → Level curve

**Overall level** and **each category level** use the **same formula**,
applied independently to each XP total (overall lifetime XP, and each
category's own XP subtotal). One function, not two curves to design,
tune, or explain separately — "Level" means the same math everywhere,
which is what makes category levels legible as a character sheet (some
categories high, some low, purely because that's where the user's real
XP landed).

Cumulative XP required to **reach** level `L` (level 1 = 0 XP floor):

```
cumulative(L) = 25 × (L − 1) × (L + 2)
```

Equivalently: the XP cost to go from level `L` to `L+1` is `50 × (L+1)` —
each level costs 50 more XP than the previous level did. This is the
"psychologically understandable" property the constitution asks for: it's
explainable in one sentence, not a hidden exponential curve.

| Level | Cumulative XP | Level | Cumulative XP |
|---|---|---|---|
| 1 | 0 | 11 | 3,300 |
| 2 | 100 | 12 | 4,000 |
| 3 | 250 | 13 | 4,800 |
| 4 | 450 | 14 | 5,700 |
| 5 | 700 | 15 | 6,700 |
| 6 | 1,000 | 20 | 10,450 |
| 7 | 1,350 | 30 | 23,200 |
| 8 | 1,750 | 40 | 41,700 |
| 9 | 2,200 | 50 | 63,700 |
| 10 | 2,700 | | |

Sanity check against onboarding: a plausible retroactive profile (ran a
first 5K, visited 3 new countries, graduated college, learned to swim,
read 12 books last year, attended a concert) totals roughly 2,000–2,500
XP — landing a brand-new user around **level 9–10** on day one. That's
the "this already looks like my life" moment the constitution wants.

At the other end, level 50 (~64k lifetime XP) requires genuinely years of
accumulated major/exceptional achievements across categories — not
reachable by grinding small ones, which is the intent. The formula has no
hard cap; it keeps extrapolating for the rare power user, but there's no
need to hand-author a table past level ~20 for MVP purposes.

**This curve is a calibrated starting guess, not settled truth** — flag
for revisit once there's real completion data (see §7).

### 3.4 Required write-up: XP / level model

1. **User problem.** Users need a single legible number that turns a
   lifetime of real accomplishments — big and small — into visible
   progression, without cheapening either the small wins or the huge
   ones, and without it feeling arbitrary or gameable.

2. **Mechanic.** Fixed discrete XP values per achievement (§3.1) are
   summed into an append-only per-user XP ledger (one immutable row per
   grant, referenced by `xpLedgerEntryId` so it can be individually
   reversed — not a mutable counter). Cumulative XP maps to level via the
   fixed formula in §3.3, applied identically to the overall total and to
   each category subtotal.

3. **Why it works.** Fixed bands keep the scale legible instead of every
   achievement inventing its own number. An append-only ledger keeps
   history auditable and cleanly reversible. Increasing level costs mean
   early levels come fast (rewarding onboarding and casual users) while
   later levels require genuinely major accomplishments, not grinding.
   Sharing one formula between overall and category levels makes "Level"
   mean one consistent thing everywhere.

4. **Possible unintended behavior.**
   - Users padding XP via user-created achievements with inflated
     self-assigned values, or via trivially easy near-duplicate
     self-created "achievements" (e.g., "Read a book" created ten times
     with different titles) to grind XP without real diversity of
     accomplishment.
   - Users stacking many small user-created achievements into one
     category to inflate that category's level without much real effort.
   - Self-report trust abuse — marking things "completed" that didn't
     happen, purely to watch the number go up.
   - Duplicate/overlapping achievements (a built-in one and a
     user-created near-copy) double-counting the same real accomplishment.
   - "Complete, screenshot the celebratory unlock, immediately undo,
     redo" as a way to farm the unlock moment itself, if undo/redo isn't
     wired through the same single ledger entry.

5. **Proposed safeguards.**
   - **Cap user-created XP by default.** Achievement creation defaults to
     the Small/Moderate bands (10–500) via a short guided suggestion (see
     MVP version below); the Major band (500–2,500) requires an explicit
     "this is a bigger deal" escalation; the Exceptional band
     (2,500–10,000+) is **reserved for built-in/AI-vetted content only**
     in v0.1 — a user cannot self-assign Exceptional XP to their own
     creation. This is the single highest-leverage safeguard against
     early abuse, and it's cheap to implement.
   - **Ledger entries are reversible, not decrementable.** Undo reverses
     the exact entry by ID (§1.4), so there's no path to double-grant via
     complete/undo/redo cycling — redo simply creates a new entry the
     same as any fresh completion, and undo removes exactly one.
   - **Soft duplicate nudge, not a block.** At completion time for a
     user-created achievement whose name/criteria closely match an
     existing built-in or already-completed item, show a non-blocking
     prompt ("This looks similar to '<name>,' which you already
     completed — still log this as separate?"). Consistent with
     trust-first philosophy — nudge, don't gatekeep.
   - **Leaderboards structurally reduce the incentive.** Per the
     constitution, leaderboards prioritize friends/category/season over
     global lifetime XP, so there's no single global "highest XP wins"
     target worth min-maxing against strangers in the first place.
   - **XP is never gated behind verification**, so the trust-first
     default holds — but verification level is visible on the profile
     independent of XP, giving competitively-minded users a legitimate
     way to stand out (credibility) without needing the app to police XP
     itself.

6. **MVP version.** Fixed XP band table (§3.1) for all built-in
   achievements. User-created achievements get a short decision-tree
   suggestion at creation time (binary one-time vs. quantified-target vs.
   record/time-bound) that defaults into Small/Moderate, with a single
   explicit escalation step capped at Major (2,500) — no Exceptional band
   available to user-created content in v0.1. No automated
   review/moderation queue yet (out of scope given a handful of users),
   but the band cap itself is a day-one structural requirement, not
   optional polish.

7. **Possible future expansion.** Community-sourced XP calibration (once
   many users complete the same user-created achievement, suggest a
   consistent value or promote it into the shared built-in library with a
   reviewed higher band); AI-assisted XP suggestions based on similar
   completed achievements; a lightweight review queue letting a
   user-created achievement request Exceptional-band XP with actual
   review.

---

## 4. Quest chains

Two worked examples beyond the constitution's 5K chain, in different
categories, plus one forward-reference example.

### 4.1 Adventure — "Peak Bagging"

| Rung | Achievement | XP |
|---|---|---|
| 1 | Hike a peak over 5,000 ft | 30 |
| 2 | Hike a peak over 8,000 ft | 75 |
| 3 | Hike a peak over 10,000 ft | 150 |
| 4 | Summit your first 14er (14,000 ft) | 500 |
| 5 | Summit five different 14ers | 1000 |
| 6 | Summit a peak over 6,000 m (e.g., Aconcagua-tier) | 5000 |

### 4.2 Skills — "Language Fluency"

| Rung | Achievement | XP |
|---|---|---|
| 1 | Learn 100 words in a new language | 20 |
| 2 | Complete a beginner course milestone | 50 |
| 3 | Hold a 5-minute conversation | 150 |
| 4 | Pass an A2/B1-equivalent proficiency exam | 400 |
| 5 | Become conversational in daily life (B2-equivalent) | 750 |
| 6 | Achieve full fluency (C1-equivalent) | 2000 |

### 4.3 Forward-reference only — Money: "Emergency Fund → Financial Independence"

Not built at MVP (Money has no seed content per §2) — included purely to
show the pattern extends cleanly once Money content is designed:

| Rung | Achievement | XP |
|---|---|---|
| 1 | Save your first $500 | 30 |
| 2 | Save $1,000 | 100 |
| 3 | Save a 3-month emergency fund | 500 |
| 4 | Reach $10,000 net savings | 750 |
| 5 | Reach $50,000 net worth | 1500 |
| 6 | Reach $100,000 net worth | 2500 |

### 4.4 Chain mechanics

- Completing rung N transitions rung N+1 from `notDiscovered` to
  `discovered` automatically, with a prompt to add it to Active — it is
  **never auto-added to `active`**, because that could silently exceed
  the user's quest-slot caps (§6) or override something they'd rather
  pursue instead. Respect their agency and their slots.
- **Higher rungs auto-complete lower ones.** If a user completes rung 4
  directly (e.g., they already run sub-22:30 without ever logging "first
  5K"), the system retroactively marks rungs 1–3 as `completed` too
  (with their XP granted), rather than leaving a confusing gap or forcing
  the user to backfill trivial steps they've clearly already cleared.
  Chains are scaffolding for people who need it, not a mandatory gate for
  people who don't.
- Each rung is completable exactly once per user, same as any other
  achievement (§1.4) — no re-grinding a chain rung for repeat XP.
- Abandoning or pausing a rung uses identical, non-punitive mechanics and
  copy as any standalone achievement — no special "chain broken" framing.
  Completed rungs stay completed permanently regardless of what happens
  to later ones.

### 4.5 Required write-up: quest chain pattern

1. **User problem.** Enormous or vague goals ("get in shape," "learn
   Spanish," "become financially secure") cause users to never start, or
   to quit early because the gap between today and the big goal feels too
   large to register as progress.

2. **Mechanic.** An ordered sequence of otherwise-normal achievements
   (rungs), each individually achievable on a realistic near-term
   timeframe, where completing one surfaces the next as `discovered`
   (never auto-`active`) and XP increases rung-over-rung to honestly
   reflect growing difficulty.

3. **Why it works.** Breaks an intimidating goal into already-familiar,
   individually celebratory units; each rung is a real completion, not an
   artificial checkpoint; because a chain rung is just a normal
   achievement with a `questChainId`, every existing state/verification/
   XP rule applies automatically with zero special-case logic.

4. **Possible unintended behavior.**
   - Users feeling obligated to complete rungs strictly in order even
     when their real-life accomplishment already clears a later rung —
     reintroducing exactly the productivity-guilt the constitution
     forbids.
   - A chain implying there's one "correct" path through a life domain
     (e.g., a running chain that's entirely about speed ignores distance,
     trail, or injury-recovery goals), which can feel narrow or
     discouraging to non-competitive users.
   - Abandoning a chain mid-way feeling like a bigger failure than
     abandoning a standalone goal, purely because a chain visually
     implies "you were supposed to keep going."

5. **Proposed safeguards.** Auto-complete-lower-rungs (§4.4) directly
   solves the ordering problem. Chains are presented as one of several
   equally valid discovery surfaces, never the only path to a domain —
   standalone, non-chain achievements in the same category always coexist.
   Pause/abandon on a chain rung uses identical copy and mechanics to any
   other achievement; no "chain broken" messaging exists anywhere in the
   product.

6. **MVP version.** A small, fixed set of hand-authored chains (the
   constitution's 5K chain plus §4.1 and §4.2 here — roughly 3 chains at
   launch) implementing the auto-surface-next-rung and
   auto-complete-lower-rungs rules. No dynamic or AI-generated chains yet.

7. **Possible future expansion.** AI-generated personalized chains
   bridging a user's current stat to a stated goal; branching chains
   reflecting multiple valid paths to the same broad goal (speed vs.
   distance vs. trail running); user-created chains; friends' progress
   shown per rung.

---

## 5. Rarity v0.1

Confirmed direction (per `docs/architecture.md`): rarity ultimately
derives from **real completion aggregates**, computed by the backend —
never hardcoded per-achievement. That computation is `app-engineer`'s
work later and isn't needed for M0.

**What `provisionalRarity` means for seed content in the meantime:** a
designer-assigned, explicitly-labeled *placeholder* estimate of how rare
an achievement would be across a broad general population attempting it
— used only for early browse/discovery sorting (e.g., surfacing "rare"
achievements as a discovery lane) until real completion data exists to
replace it. It is never presented to end users as a statistic ("X% of
people completed this") — only real computed rarity may claim that,
because with a handful of users any real percentage would be both
meaningless and potentially identifying (e.g., "1 of 3 users" reveals who).

**Heuristic for assigning `provisionalRarity`** (rough estimate of
lifetime completion rate in the general population, not just app users —
illustrative, not scientific):

| Label | Rough population rate | Example from §3.2 |
|---|---|---|
| Common | > 50% | Attend a live concert |
| Uncommon | 15–50% | Run a first 5K |
| Rare | 3–15% | Run a marathon |
| Epic | 0.5–3% | Complete an Ironman; earn a PhD |
| Legendary | < 0.5% | Summit an 8,000 m peak |

**Switchover rule (spec now, activate later):** once an achievement has
been completed by at least **30 distinct users**, computed rarity
replaces the provisional label for that achievement in all
user-facing surfaces. Below that threshold, fall back to
`provisionalRarity`. At current scale ("a handful of users"), essentially
everything will show the provisional label for a long time — that's
expected and fine; this rule just needs to exist in the code now so it
activates automatically as usage grows, without a follow-up migration.

---

## 6. Active quest limits

Confirms and refines the constitution's "3 Main / ~5 Side / unlimited
Backlog" model into implementable rules:

- **Main Quest** = `state = active` and `questSlotType = main`. Hard cap:
  **3 concurrent**.
- **Side Quest** = `state = active` and `questSlotType = side`. Hard cap:
  **5 concurrent** (the constitution says "approximately 5"; hard-capping
  at exactly 5 for v0.1 removes an ambiguity that would otherwise become
  an implementation bug — trivially easy to loosen later if testing shows
  it's too tight).
- **Backlog** (`state = interested`) = unlimited, as specified.
- **`paused` quests never count against either cap.** This is what makes
  pausing a real, guilt-free "take a break" mechanic rather than a
  permanent slot loss — a user can pause all 3 Main Quests and start 3
  fresh ones without penalty.

**On a 4th Main Quest attempt:** block the transition, show the 3
current Main Quests, and require one explicit choice before proceeding:

1. Demote one existing Main Quest to Side Quest or Backlog, freeing a
   slot for the new one, or
2. Add the new one as a Side Quest instead, or
3. Cancel and leave things as they are.

Never silently overwrite an existing quest. Never offer a paid way to
add a 4th slot (hard constraint, not a v0.1-only rule). Same flow at a
6th Side Quest attempt. Exact screen/interaction design for this swap
flow belongs to `ux-ui-designer`; the underlying rule (block + require an
explicit choice, no silent drops, no purchase path) is specified here.

**Resuming a paused quest:** re-check caps at resume time using the
quest's retained `questSlotType`. If that track still has room, resume
into it automatically. If not (e.g., the user has since filled all 3
Main slots with other quests), prompt the same three-way choice as above
instead of silently exceeding the cap.

**Quest chains respect the same caps** — completing a rung surfaces the
next one as `discovered` only (§4.4), it never auto-fills a quest slot,
so a chain can never silently push a user over their Main/Side limits.

---

## 7. Open questions / flags for coordination

None of these block scaffolding — all are provisional and reversible —
but they're genuine judgment calls worth surfacing rather than treating
as settled fact:

**For the founder:**

- The XP→level curve in §3.3 (level 50 ≈ 63,700 lifetime XP) is a
  calibrated guess with no ground truth yet. Worth a gut-check once real
  usage exists: does level progression *feel* right at the pace this
  produces, especially for a founder using their own retrospective data?
- Confirm the category scoping call in §2 (six seeded, four
  defined-but-empty) matches founder expectations for what a first
  release should visibly contain — this was made as an MVP scoping
  decision within my remit, but it does mean Money/Career/Relationships/
  Maker-Projects will look sparse in the browse UI at launch.
- The Exceptional XP band (2,500–10,000+) being fully reserved from
  user-created content in v0.1 (§3.4) is a real constraint on power users
  who want to log a genuinely massive self-defined goal at launch. I
  think this is the right early-abuse tradeoff, but it's a UX limitation
  worth the founder being aware of, not just an implementation detail.

**For coordination:**

- `ux-ui-designer`: needs the quest-slot swap flow (§6) and the
  undo-completion confirmation copy (§1.4) as concrete screens; also the
  presentation rules for `isSecret` achievements and for the
  user-created-XP guided-suggestion flow (§3.4 MVP version).
- `app-engineer`: the two-table split (`AchievementDefinition` /
  `UserAchievementInstance`), the lazy-row-creation rule for
  `discovered`, the ledger-entry-reversal design for undo, and the
  rarity switchover threshold (§5) are all meant to be directly
  implementable from this doc without further design decisions — flag
  back anything that isn't.
- `qa-critic`: §3.4 and §4.5 are written specifically to hand you the
  failure modes I'm aware of already (XP padding, duplicate/near-duplicate
  farming, chain-ordering guilt, undo/redo double-grant) — please look
  past those for anything not covered here, especially around
  verification-level social pressure and leaderboard interactions once
  those exist.
