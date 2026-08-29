# Seed Achievement Library — v1 companion notes

Status: companion to `backend/supabase/seed/achievements.v1.json`. Written
by `product-designer`, extending (not redesigning) `docs/domain-model.md`
§1–§5 per `BACKLOG.md` NOW. Read that doc first — this one only explains
the content decisions made while filling it out to MVP size.

---

## 1. Target count per category, and why

| Category | Count in v1 | Of which quest-chain rungs |
|---|---|---|
| Fitness | 23 | 6 (5K chain) |
| Adventure | 22 | 6 (Peak Bagging) |
| Travel | 18 | 0 |
| Education | 11 | 0 |
| Skills | 18 | 6 (Language Fluency) |
| Experiences | 15 | 0 |
| **Total** | **107** | 18 |

**Why ~107, not fewer or many more.** The brief for this task explicitly
warned against two failure modes: too thin to browse (a handful of
examples repeated from the domain model) and an unreviewable content
dump. ~15–23 per category is enough that Discover's category lanes,
"nearby difficulty," and "rare achievements" surfaces (per
`docs/product-constitution.md` → Discovery) all have real material to
draw from without every user seeing an identical, exhausted list within a
week — but it's still small enough that the founder or `qa-critic` can
read the whole category in a couple of minutes and sanity-check it, which
a 200+-item list would not allow. This is a **reversible content
decision**: adding, retiring, or re-banding individual entries later
requires no schema change (per `docs/domain-model.md` §2's own framing of
category scoping as reversible) — it's editing rows, not redesigning
anything.

**Why category counts aren't equal.** I resisted padding categories to
match a round number, per the task's explicit instruction not to pad with
near-duplicates:

- **Fitness (23) and Adventure (22)** are the largest because both have
  genuine, non-redundant difficulty ladders in real life (distance,
  speed, elevation, load) that don't feel like duplicates — a sub-30 5K
  and a sub-20 5K are meaningfully different accomplishments, not the
  same achievement restated.
- **Education (11) is deliberately the smallest.** Institutional
  educational milestones (diplomas, degrees) are naturally finite — there
  are only so many non-arbitrary rungs before an entry starts to feel
  invented just to hit a count (e.g., I did *not* add a fake "read 100
  books" on top of "read 12 in a year" / "read 50 lifetime" merely to pad
  the list). A short, honest category list is better than a padded one.
- **Experiences (15) has no Exceptional-band (2,500–10,000+) entry**,
  and that's intentional, not an oversight — see §2 below.

## 2. Band coverage — where it's genuine vs. where I didn't force it

The brief asked for real breadth across all four XP bands "where
genuinely warranted, not just clustering in Small/Moderate." Fitness,
Adventure, Travel, and Skills each have real entries in all four bands
(Small/Moderate/Major/Exceptional) because those domains have real
lifetime-scale endpoints (Everest, visiting every country, full fluency,
mastery of a craft). Education tops out at Epic-tier PhD (5000) rather
than reaching into 7500/10000 — there isn't an honest "even bigger than a
PhD" institutional milestone to invent. Experiences has no Exceptional
entry at all: almost everything in this category is a single day or
evening's experience, not a multi-year commitment, so forcing a
2,500+ XP "Exceptional lifetime achievement" here would have meant
inventing something disingenuous just to fill a cell in a table. I'd
rather a category's ceiling be honest than complete.

## 3. Corrections made to already-settled domain-model content

Two fixes to `docs/domain-model.md` itself, surfaced here rather than
silently patched, per this task's instruction to flag rather than
silently reinterpret:

1. **Peak Bagging chain rung 2 was mis-banded.** §4.1 lists "Hike a peak
   over 8,000 ft" at 75 XP. 75 is not one of the fixed discrete values in
   §3.1/`XPBand.swift` (small band is 10/15/20/25/30/40/50) — this was a
   pre-existing bug in my own earlier spec, the same category of error
   the doc's §3.3 level-curve table already had and got corrected for.
   Seeded as **50 XP** instead (still small band, keeps the chain
   monotonically increasing: 30 → 50 → 150 → 500 → 1000 → 5000).
   `app-engineer`: if `docs/domain-model.md` §4.1 is treated as a source
   of truth anywhere in code, it should be corrected to 50 to match.
2. **Duplicate achievement across categories, resolved by dropping one.**
   §3.2's Education table lists "Become conversational in a new language"
   (binary, 750 XP) as a standalone entry. §4.2's Language Fluency chain
   (Skills category) already has, as its rung 5, "Become conversational
   in daily life (B2-equivalent)" — also 750 XP and describing the same
   real-world accomplishment. Keeping both would let a user claim two
   completions (and double XP) for one underlying accomplishment, exactly
   the "duplicate/overlapping achievements double-counting the same real
   accomplishment" failure mode §3.4 already flags. I dropped the
   standalone Education entry; language learning now lives entirely in
   the Skills chain, which covers the full arc (vocabulary → course
   milestone → conversation → certified proficiency → conversational →
   full fluency) better than a single flat Education entry did anyway.

## 4. Onboarding-eligible subset (for the ~25–40-card triage deck)

`docs/wireframes.md` §1 needs a separate, smaller, curated deck — "on the
order of 25–40 curated, high-hit-rate common achievements" — distinct
from this full 107-item library. I selected **30**, five per seeded
category, using three filters:

- **Binary or simple cumulative only** — no `thresholdRecord` entries
  (sub-30 5K, bench press weights, plank duration, deadlift). Onboarding
  is a zero-data-entry swipe deck (per the wireframe: "no XP value... no
  description wall," Done/Want to do/Not interested only); asking someone
  to recall an exact past time or weight to self-report "Done" belongs on
  the detail screen later, not the triage card.
- **High hit-rate** — skewed toward things a broad cross-section of adults
  plausibly has or hasn't done, to make the "this already looks like my
  life" moment land fast, per the onboarding brief.
- **Unambiguous** — a clean yes/no without needing a definition argument
  (e.g. "Graduate high school" is unambiguous; something like "become
  successful at your career" would not be, which is exactly why Career
  has no seed content at all yet, per §2 of the domain model).

Onboarding-eligible (30 of 107), by category:

- **Fitness:** Do your first pull-up · Run your first 5K · Complete a 10K
  run · Complete a half marathon · Complete a marathon
- **Adventure:** Go camping for the first time · Skydive · Complete a 3+
  night backpacking trip · Summit your first 14er (14,000 ft) · Go scuba
  diving for the first time
- **Travel:** Take your first flight · Get your first passport · Visit a
  new country · Take a solo international trip · Visit 10 countries
- **Education:** Graduate high school · Read 12 books in a year ·
  Graduate college (bachelor's degree) · Complete an online course · Earn
  a master's degree
- **Skills:** Cook a meal from scratch (first time) · Learn to swim · Get
  a driver's license · Learn to play a song on an instrument · Learn to
  ride a bike
- **Experiences:** Try a new cuisine · Attend a live concert · Meet a
  personal hero · See a total solar eclipse · Volunteer for a cause you
  care about

The remaining 77 are library-only for now — reachable via Discover, not
the onboarding deck. A few of these (Marathon, Master's degree) skew
toward Major-band XP despite being "common" in the sense of being
unambiguous yes/no facts most people can self-report instantly, even
though relatively few people have actually done them — that's fine; "high
hit-rate" in the wireframe's sense is about speed/clarity of the
decision, not about everyone answering "Done." A few aspirational,
lower-hit-rate cards mixed into the deck (Skydive, Summit your first
14er) intentionally double as "Want to do" bait for the starter-quest
suggestions at the end of onboarding, per the wireframe's Profile Reveal
step.

I did not include any `thresholdRecord` or deep-tier (Epic/Legendary)
entries in the onboarding deck at all — that's a hard filter, not a soft
preference, given the deck's explicit "no data entry" design constraint.

## 5. Proposed secret achievements

**Important scoping note, per this task's instructions: none of these
are in `achievements.v1.json`.** Every one of them needs a trigger
condition that inspects a user's *entire* achievement/category state
(counts across many rows, cross-category joins, timestamp deltas) rather
than a single stat crossing a single bound. That's fundamentally outside
what `CompletionCriteria`'s three cases (`binary` /
`cumulativeCount` / `thresholdRecord`) are built to express — each of
those evaluates exactly one measured value against exactly one
achievement's own target. Bolting a fake `{"type": "binary"}` onto these
in the seed JSON now would misrepresent them as ordinary,
independently-completable achievements, when they actually depend on a
separate evaluation pass over the rest of the user's data. **This is new
engineering scope for `app-engineer`: a "meta-achievement" evaluator that
runs after any normal completion/level-up event, checks each
meta-achievement's condition against the user's full state, and — if
newly satisfied — writes a `UserAchievementInstance` straight to
`completed` (a jump `notDiscovered → completed` in one step, same pattern
already established for `integrationDetected` achievements in
§1.4's non-linear transitions list, so this isn't a new *kind* of
transition, just a new trigger source for it) and grants its XP via the
same `XPLedger`.** Once that mechanism exists, these can be added to the
catalog as ordinary `AchievementDefinition` rows with `isSecret: true`
and `category: general` — the definition shape itself doesn't need to
change; only the evaluation path does.

All five constitution examples (`docs/product-constitution.md` → Secret
Achievements) are covered, plus one original addition consistent with the
"may be humorous... should not manipulate users into unhealthy behavior"
guidance:

1. **"Jack of All Trades"** (cross-category completion). *Concept:* the
   user has at least one `completed` achievement in every one of the 10
   browsable categories (`general` excluded). *Trigger, conceptually:*
   `count(distinct category of completed instances) >= 10`. XP: 1000
   (major). Note: at MVP, four categories have no built-in content, so
   this is only reachable via user-created achievements in Money/Career/
   Relationships/Maker-Projects — intentional, since it gives those empty
   categories a reason to get a user's first entry rather than sitting
   permanently unused; not a bug to fix before launch.
2. **"Side Quest Legend"** (25 Side Quests completed). *Concept:* 25
   lifetime completions that were tracked as Side Quests
   (`questSlotType = side`) at completion time. *Trigger:*
   `count(completed instances where quest_slot_type = 'side') >= 25`. XP:
   750 (major).
3. **"Against All Odds"** (an unusually difficult achievement).
   *Concept:* the user has completed at least one achievement whose
   rarity is Legendary (provisional label pre-30-completions, computed
   rarity after — per §5's switchover rule, whichever is authoritative at
   evaluation time). XP: 500 (moderate/major boundary) — deliberately a
   bonus on top of the underlying achievement's own XP, not a
   replacement, since the point is to additionally *notice* the
   achievement was rare, not to be the reason someone chases it.
4. **"Trailblazer"** (five outdoor achievements). *Concept:* this is the
   one example that doesn't map cleanly onto the existing one-category-
   per-achievement model — "outdoor" cuts across Adventure and parts of
   Fitness/Travel, and there's no tag for that today. Two honest options,
   flagged for `app-engineer`/founder rather than decided silently here:
   (a) MVP proxy — just count Adventure-category completions (`>= 5`),
   accepting that a Fitness trail-running or Travel-national-park
   completion won't count even though it's clearly "outdoor" too; or (b)
   add a genuine cross-cutting tag (e.g. `isOutdoor: Bool` on
   `AchievementDefinition`, or a small `tags` array) — a real, if small,
   schema addition. I recommend (a) for v1 (zero schema change, good
   enough given Adventure already contains the overwhelming majority of
   genuinely outdoor content) and revisiting (b) only if it turns out to
   matter once usage data exists. XP: 300 (moderate).
5. **"Renaissance"** (Level 10 in multiple categories). *Concept:* at
   least two categories have independently reached category Level 10 (via
   the shared level curve, §3.3), not necessarily on the same day. XP:
   1500 (major).
6. **"The Long Game"** (original addition). *Concept:* complete an
   achievement whose `completedAt` is 2+ years after its `discoveredAt`
   (or `activatedAt`, if that's earlier and set). This deliberately
   rewards patience and picking something back up rather than speed or
   volume — a direct expression of "no productivity guilt": pausing and
   abandoning are explicitly non-punitive (§1.4), and this secret makes
   coming back to something years later a small celebrated moment instead
   of something the system only ever measured negatively. XP: 250
   (moderate) — intentionally modest; this isn't meant to be chased, just
   noticed if it happens.

All six use `category: general` and `source: builtIn` once implemented,
consistent with the `Category.general` pseudo-category already reserved
for exactly this purpose in `Category.swift`.

## 6. Open questions

**For the founder:**

- None of the content decisions above materially change UX, monetization,
  or product direction on their own — this is squarely a reversible
  content pass. Flagging just for awareness: Education is visibly the
  thinnest seeded category (11 items vs. 18–23 elsewhere) by design, not
  oversight; worth a gut-check that a first-run Discover screen showing a
  noticeably shorter Education lane next to a much longer Fitness one
  feels fine rather than like a bug.

**For coordination:**

- `app-engineer`: the meta-achievement evaluator described in §5 is new
  scope — not an extension of `CompletionCriteria`. It needs to run
  against the user's full achievement/category state (not a single
  `UserAchievementInstance`), most naturally as a check after any
  completion or level-up event. None of the six proposed secrets are in
  `achievements.v1.json` yet; add them once the evaluator exists.
  Separately: there is currently no table storing quest-chain-level
  metadata (a chain's own display name, e.g. "5K Questline" — the
  wireframe's achievement-detail screen shows "Part of the 5K Questline ·
  Step 3 of 6," but `questChainId` today is just a grouping UUID with no
  associated name/description anywhere). That's needed before that
  wireframe detail can actually be built; flagging since it surfaced
  while writing this content, not because it's this doc's job to spec it.
- `ux-ui-designer`: the onboarding deck (§4) should present its 30 cards
  interleaved across categories (not grouped/blocked by category), per
  the wireframe's "single continuous stream... mixed across categories."
  I picked the *set*; shuffling/ordering is presentation, your call.
- `qa-critic`: worth specifically stress-testing the "Jack of All Trades"
  secret (§5.1) once user-created achievements exist in the four
  currently-empty categories — that's the one path in this whole set of
  107 + 6 where a user could self-create a trivially easy achievement
  purely to unlock a secret, since Money/Career/Relationships/Maker-
  Projects have no built-in content to compare a self-created one
  against for the "does this look like a real accomplishment" nudge in
  `docs/domain-model.md` §3.4.
