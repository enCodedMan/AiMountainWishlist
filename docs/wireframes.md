# Wireframes — Onboarding, Home, Achievement Detail, Profile

Status: **draft spec** for M0 (`BACKLOG.md` NOW). Owned by `ux-ui-designer`.
This is information architecture and interaction structure, not a visual
mockup — `app-engineer` builds the SwiftUI from this. XP numbers,
achievement taxonomy, and category list are `product-designer`'s domain
model to finalize separately; this doc treats them as inputs.

Every section is graded against the Product Test in
`docs/product-constitution.md` and the "Simple Surface, Deep System"
principle from `CLAUDE.md`: a casual user must be able to operate the
screen immediately; a power user must be able to find more without the
casual user ever seeing it.

Navigation IA referenced throughout: three bottom tabs — **Home**,
**Discover**, **Profile**. There is no separate "Quests" tab; the active
quest list is reached from Home (`See all quests`) and full stats/charts/
leaderboards/trophy case live under Profile. This keeps the tab bar at
three items and keeps the power-user surfaces one tap away rather than
competing for primary chrome.

---

## 1. Onboarding

### Primary user intent
Go from "I just installed this" to "this already looks like my life" in
a few minutes, without filling out a form. The user should never see a
blank Level 1 / 0 XP state — per the constitution, onboarding's job is to
retroactively populate a life profile, not start one from nothing.

### Structure

**Screen 1 — Welcome.** One screen. App name, one-line value prop ("Turn
your life into a scoreboard"), single primary CTA `Build my profile`.
Secondary, low-emphasis link: `Skip for now` (goes straight to a
genuinely-blank Home only if the user explicitly opts out — see Edge
Cases). No account-creation friction shown here; auth happens before or
after per app-engineer's flow, not this doc's concern.

**Screens 2–N — Triage deck (the core interaction).** A single continuous
stream of achievement cards, mixed across categories (not pre-sorted by a
category-picker step — asking the user to configure categories before
delivering value would itself be friction the constitution warns
against). Each card shows only: category icon/tag, achievement name, one
short line of context (e.g. "Run a 5K without stopping"). Nothing else —
no XP value, no rarity, no description wall.

Three triage actions, always available as both a swipe gesture and a
visible on-screen button (button row required for accessibility, not
optional):

```
┌─────────────────────────────┐
│  ADVENTURE                   │
│                               │
│      Climbed a Mountain      │
│   Reached the summit of any  │
│   named peak                 │
│                               │
├─────────────────────────────┤
│  ✕ Not interested            │
│  ★ Want to do                │
│  ✓ Done                      │
└─────────────────────────────┘
   ↑ ambient tally, top of screen
   "Building your profile · Level 4 · 1,240 XP"
```

- **Done** → immediately becomes a completed achievement, contributes XP
  and category XP to the running total.
- **Want to do** → goes into the user's backlog; a subset becomes
  suggested starter quests at the end of the deck.
- **Not interested** → discarded, never surfaced again in Discover.

Each decision commits immediately (not batched at the end), so if the
user abandons mid-deck, whatever they've triaged so far is already saved
— the "never blank" guarantee holds even on interruption.

**Speed and pacing.** Designed for one card per second or faster for a
user who's moving fast; no forced minimum dwell time, no per-card
animation that blocks the next card. There is deliberately **no
per-card unlock ceremony** — playing a full celebration 30–40 times in a
row during onboarding would be the opposite of fast and would cheapen the
real unlock moment later. Instead, feedback is a single ambient,
non-blocking counter at the top of the screen ("Level 4 · 1,240 XP") that
ticks up quietly as the user triages. A thin progress indicator (dots or
a slim bar, not a percentage) shows the deck has a visible end.

The deck itself is short by design — on the order of 25–40 curated,
high-hit-rate common achievements, not an exhaustive library dump. A
`Done for now` exit is always reachable (not just at the very end) so a
user who wants to stop at card 12 isn't trapped.

**Final screen — Profile Reveal.** One screen, the emotional payoff of
the flow:

- Overall Level and XP, shown large — the one moment in onboarding that
  gets real visual weight.
- Category levels, but **only for categories the user actually touched**
  — untouched categories are omitted here entirely rather than shown at
  "Level 0," which would look like failure/incompleteness. (They appear,
  unranked, later in Profile once the user has any activity there.)
- A short, editable list of suggested starter quests pulled from "Want to
  do" picks (auto-selected top 3, e.g. most recently swiped or highest
  interest signal — exact selection logic is product-designer's call).
  User can tap to swap any of the three; this is optional, not a
  required configuration step — a `Looks good` default path exists that
  requires zero taps.
- Single primary CTA: `Enter my scoreboard` → Home.

### Primary action
Triage the current card (Done / Want to do / Not interested). On the
reveal screen: `Enter my scoreboard`.

### Secondary actions
`Done for now` (early exit from the deck), `Skip for now` (opt out of
onboarding entirely, screen 1 only), adjusting the 3 auto-picked starter
quests on the reveal screen.

### Empty state
Not applicable in the traditional sense — the deck is never empty
(curated, finite, server-provided). The only true empty case is a user
who marks everything "Not interested" and nothing "Done"/"Want to do":
they land on Home at a genuine Level 1 / 0 XP with an empty quest list.
This is honest, not a bug, and Home's own empty states (below) handle it
gracefully with a path into Discover.

### Populated state
Described above — Profile Reveal with level, XP, touched category
levels, and starter quests.

### Edge cases
- **User backgrounds/kills the app mid-deck.** Every triage decision is
  already committed, so relaunch resumes the deck where it left off (or
  drops the user straight to Home if they don't return — their partial
  profile is already real, not discarded).
- **User taps `Skip for now` on screen 1.** Goes to a real blank Home. We
  accept this as an explicit, informed opt-out rather than forcing
  onboarding — but Home's empty state must still make the very next step
  obvious (see Home § Empty state).
- **Ambiguous/overlapping cards** (e.g., a "Ran a marathon" Done implies
  a 5K was also technically done). Deck curation to avoid this is a
  content/taxonomy problem for `product-designer`, not a screen-structure
  one — noted here so it isn't silently dropped.
- **Very long achievement names or descriptions** on a card: single-line
  truncation with the card layout unaffected; never resize the card ✕or
  push the button row off-screen.

### Accessibility
- Every triage action is a real, labeled, ≥44pt button — swipe gestures
  are an accelerator, never the only path (required for VoiceOver and
  motor-accessibility users).
- VoiceOver reads: achievement name, category, and the three action
  labels; the ambient level/XP counter is announced as a polite,
  non-interrupting update, not forced onto every card's focus order.
- Dynamic Type: card text reflows; at largest sizes the context line may
  truncate with "more," never the achievement name.
- Reduce Motion: card advance becomes a simple cross-fade instead of a
  swipe/fling animation.
- Light haptic tap on each triage action, distinct (not just different
  color) for Done vs. Want to do vs. Not interested, and this respects
  the system haptics setting.

### Deliberately NOT shown during onboarding
- XP value or rarity per card (would slow the pace and turn triage into
  grading).
- Verification/evidence prompts.
- Friends, leaderboards, or any social surface.
- Any monetization/upsell messaging.
- A full goal-configuration form (target numbers, deadlines, milestones)
  — that belongs to the separate "create a quest" flow, not onboarding.
- Streaks or any time-pressure messaging.

---

## 2. Home

### Primary user intent
A quick "check the scoreboard" glance: orient, feel progress, decide
whether there's something worth doing, then leave. Per `CLAUDE.md`, a
great session here can last 20 seconds. Home is explicitly the one
screen that must answer four questions and nothing more by default:

1. Where am I?
2. What am I working toward?
3. What changed recently?
4. What interesting thing could I do next?

### Structure (top to bottom, one screen, no dashboard grid)

```
┌───────────────────────────────┐
│  [avatar]  Level 7             │  ← Where am I?
│  ▓▓▓▓▓▓▓▓▓░░░  1,240 / 2,000   │
├───────────────────────────────┤
│  QUESTS                        │  ← What am I working toward?
│  • Sub-25 5K        62%        │
│  • Save $5,000       40%       │
│  • Visit 10 Nat'l Parks  3/10  │
│           See all quests →     │
├───────────────────────────────┤
│  RECENT                        │  ← What changed recently?
│  ✓ Ran a 10K · 2 days ago      │
│  ↑ Level 6 → 7 · 5 days ago    │
├───────────────────────────────┤
│  TRY SOMETHING NEW              │  ← What's next?
│  [ card: "Climb a 14er" ]      │
│           See more →           │
└───────────────────────────────┘
```

1. **Identity/level header.** Avatar + name (optional/small), Overall
   Level, and a single progress bar/ring for XP within the current level.
   No lifetime XP total blasted large here — that number belongs to
   Profile. Tapping the header opens Profile.
2. **Active quests module.** Up to **3** compact cards, one per active
   Main Quest (name, category, a single progress indicator — percentage
   or fraction depending on the achievement's measurement type). Tapping
   a card opens that achievement's detail screen. `See all quests` link
   handles overflow (Side Quests, Backlog) rather than listing them here.
3. **Recent activity module.** The last 1–3 things that changed:
   completions and level-ups, each with a relative timestamp. Tapping an
   item opens its (now-completed) detail screen. This is intentionally
   short-lived and personal — no friend activity here (see social
   philosophy: profile-first, not feed-first).
4. **"Try something new" module.** One to three suggested achievements
   (selection logic owned by product-designer), presented as a small
   card or carousel with a single `See more` escape hatch into Discover.
   This is a taste, not a browse grid — Home never becomes a library.

### Primary action
Whatever is most likely to matter today: tapping an active quest card to
open it and make/confirm progress (fastest path to the flagship
Mark-Complete interaction). There is no separate floating "+" button on
Home for MVP — adding a new goal happens from Discover or Profile, not
as a persistent affordance competing with the four modules above. (Open
question for founder/product-designer below.)

### Secondary actions
- Tap header → Profile (full level detail, category levels, trophy case,
  stats).
- `See all quests` → full quest list (Main/Side/Backlog).
- Tap a recent-activity item → that achievement's detail screen.
- `See more` on the discovery card → Discover tab.

### Empty state
Because onboarding guarantees existing level/XP/quests for any user who
didn't explicitly skip it, a fully blank Home should be rare. Two real
cases:

- **User skipped onboarding entirely.** Header shows Level 1 / 0 XP
  honestly. Quests module replaces its list with a single CTA: `Pick
  your first quest → Discover`. Recent module is hidden entirely rather
  than shown empty (an empty list with a header reads as broken/sad).
  Discovery module still shows suggestions — this becomes the user's
  main path forward.
- **Fresh from onboarding, zero live completions yet.** The Recent module
  is seeded with a single entry summarizing the onboarding import itself
  ("Started your profile · 12 achievements added") so the module isn't
  empty on first real open. This entry naturally ages out as real
  activity accumulates.

### Populated state
As diagrammed above — the steady-state screen for a returning user with
active quests and some history.

### Edge cases
- **More than 3 active Main Quests somehow exist** (e.g. imported oddly,
  or Side Quests included) — Home still shows only 3, chosen by whatever
  priority rule product-designer defines (e.g. most recently touched),
  with `See all quests` handling the rest. Home never grows past its
  fixed module sizes regardless of how much data exists underneath —
  this is the load-bearing rule that keeps a power user's Home identical
  in shape to a casual user's.
- **A quest's progress is not meaningfully measurable** (binary
  achievement, e.g. "Run your first 5K") — its card shows no percentage,
  just the name and category; don't fabricate a fake progress bar.
- **User has been away for months.** Recent module simply shows the last
  1–3 real events regardless of how old ("3 months ago") — no shame
  messaging, no "we missed you," no streak-loss framing, per the
  constitution's no-guilt principle.
- **Network/sync failure.** Home renders from last-known local state
  (not a spinner-blocked screen); a small, non-modal indicator (not a
  toast that steals the primary CTA) signals stale data.

### Accessibility
- Dynamic Type: level number and progress text scale without truncating;
  quest card titles wrap rather than clip.
- VoiceOver: progress is exposed as a spoken value ("Sub-25 5K quest, 62
  percent complete"), not conveyed by bar fill color alone.
- Minimum 44pt tap targets for every quest card and module link.
- Any idle/ambient animation (e.g. a subtle shimmer on the level bar)
  has a static Reduce Motion equivalent.
- Color is never the sole signal for quest progress or level-up state —
  always paired with a number or icon.

### Deliberately NOT on Home (reached only by navigating deeper)
- Full stat charts/graphs, personal-record history, seasonal summaries.
- Leaderboards and friend activity/comparison.
- Rarity percentages.
- The full list of all 10 category levels (only the overall level shows
  here; category levels live in Profile).
- The complete achievement library / browse grid (Discover owns this).
- Streak counters or any daily-engagement metric.
- Ads or upsell messaging.
- Notification/settings management.

---

## 3. Achievement Detail

This screen has two states — **browsing/pre-completion** and
**completed** — plus the transition between them, the unlock moment,
which is the flagship interaction of the entire product and gets its own
subsection below.

### Primary user intent (pre-completion)
Understand what this achievement is, see current progress, and decide
what to do about it — start it, log progress toward it, or complete it
outright.

### Visual hierarchy (pre-completion)
1. Category tag/icon + achievement name (largest element on screen).
2. One or two lines of plain-language description / completion
   criteria.
3. Progress representation appropriate to the achievement's type:
   - Binary: a status word ("Not started" / "In progress"), no fake bar.
   - Measurable: a bar or fraction tied to the underlying stat (e.g. "3
     of 10 national parks visited," or "Current best: 26:04, target:
     sub-25:00").
4. XP value and rarity, shown as a modest secondary row (e.g. "450 XP ·
   Uncommon" — no percentage until the achievement has enough real
   completions to compute one honestly, per `docs/domain-model.md` §5) —
   present because curious users look for it here, but visually
   subordinate to the achievement itself, never competing with the name
   for attention.
5. Quest chain context, if applicable: "Part of the 5K Questline · Step 3
   of 6," with a compact chain strip; tapping opens the full chain view.
6. Status controls (below).

### Primary action
Exactly one dominant button, context-dependent, pinned near the bottom
of the screen for one-handed reach:
- **Discovered / Interested:** `Start Quest`.
- **Active, binary:** `Mark Complete`.
- **Active, measurable:** `Log Progress` (opens a minimal quick-entry —
  a number pad or a single photo, not a form); `Mark Complete` becomes
  available once the target is met, or manually at any time (trust-first
  — the user is never blocked from declaring completion).
- **Completed:** no primary action button. The screen instead shows
  "Completed · [date]" and settles into a quiet, finished state.

### Secondary actions
Tucked into an overflow menu (•••) rather than competing with the
primary button, since these are lower-frequency and some are sensitive:
`Pause`, `Abandon` (never punitive — per the constitution, abandoning
loses nothing), `Add evidence/photo` (optional, for verification-
curious users), `Add note`, `Edit` (only for user-created achievements),
and — only once completed — `Add to Trophy Case` and `Share`.

### Empty state
Not applicable as a blank screen (a detail screen always represents one
specific achievement), but two graceful-degradation cases matter:
- A user-created achievement with only a name and no description renders
  with just the name/category and status controls — no broken layout,
  no placeholder "no description" text that reads as an error.
- A "Discovered" achievement the user hasn't reacted to yet shows only
  the teaser info plus `Start` / `Not interested`, no progress section
  at all (there's nothing to show progress on yet).

### Populated state
As described in Visual hierarchy above — full context, progress,
XP/rarity, chain position, and the appropriate primary action.

### Edge cases
- **Secret achievement, not yet unlocked.** Never reachable as a
  pre-completion detail screen at all — it doesn't appear in Discover or
  any list. It only becomes visible the moment it's completed (this
  screen is entered directly at the unlock/completed state).
- **Next step in a quest chain, prior step incomplete.** Shown as a
  locked preview (name visible, greyed) that explains the prerequisite
  when tapped, rather than allowing `Start Quest`.
- **Measurable achievement with no stat data yet.** Shows a "Log your
  first entry" prompt instead of a 0%-filled bar, which would read as
  discouraging rather than neutral.
- **Multiple completions arrive at once** (onboarding import, or a
  future integration syncing several at once). This screen doesn't
  change, but it must never be reached via a stack of N full-screen
  unlock ceremonies — see Batch handling below.
- **Verification pending** (evidence submitted, awaiting confirmation).
  A small, non-blocking "Pending" tag near the status row; never blocks
  the achievement from already showing as complete, since trust is the
  default.
- **Very long user-created name/description.** Truncate with an
  expandable "more," never let it push the primary action button off
  the visible area.

### Accessibility
- `Mark Complete` / `Start Quest` / `Log Progress` are always ≥44pt,
  placed within easy one-handed thumb reach near the bottom edge.
- Progress is exposed to VoiceOver as a spoken value, not just a filled
  bar.
- Rarity badge pairs an icon/label with color, never color alone.
- Light haptic confirmation when logging progress (distinct from the
  heavier haptic used at full completion, so the two are distinguishable
  by feel).

### Deliberately NOT shown on this screen
- Other users' completion times, comments, or any feed-style social
  content (profile-first, not feed-first — even once friends exist, at
  most a quiet "3 friends have done this" fact, never a comment thread).
- Leaderboard position for this specific achievement.
- Ads or upsell prompts.
- Any "don't lose your streak" or urgency messaging.
- A verification requirement gating the Mark Complete button — trust is
  the default per PD-002.

---

### 3a. The Unlock Moment (flagship interaction)

**Trigger.** The user taps `Mark Complete`, or a completion arrives
automatically (future integration). This is the single interaction in
the whole app that deserves disproportionate design care — and the one
most likely to be repeated dozens of times, so it must stay fast rather
than becoming a ceremony users start dreading.

**Design goal.** Premium and satisfying on first use; still fast and
welcome on the hundredth. The key structural decision is **tiering the
ceremony to the achievement's significance**, so routine completions stay
light while genuinely rare moments still get the big treatment the
constitution asks for.

**Information hierarchy, in order of reveal** (fast — full sequence
targets well under two seconds for the standard tier, and is
tap-anywhere-to-dismiss at every point, never modal-locking the user in):

1. **Haptic, on the exact tap-down of the button** — not waiting for any
   animation. This is the "yes, that registered" confirmation and it has
   to be instant.
2. **Achievement name + icon**, transitioning into a "sealed/completed"
   visual state — the primary visual element, first thing the eye reads.
3. **XP earned**, counting up ("+320 XP"), directly beneath the name —
   the primary number.
4. **Category XP / category level-up**, smaller, secondary row beneath
   ("Fitness +320 · Level 6 → 7") — and this row is **omitted entirely**
   if no category level changed, rather than shown as a non-event. Don't
   report nothing as if it were something.
5. **Overall level-up**, if triggered, escalates the whole moment: bigger
   haptic (a success-notification pattern, not just an impact tap), and
   this is the loudest treatment on the screen because a level-up is
   rarer and more significant than any single completion.
6. **Rarity badge**, smallest, last, most skippable ("Uncommon," with a
   percentage only once real computed rarity exists per
   `docs/domain-model.md` §5) — present for the power user who cares,
   easy to not notice for the user who doesn't.
7. **Dismiss.** Tap anywhere, or it auto-settles on its own after a
   couple of seconds into the achievement's now-updated Completed detail
   screen. No forced "OK" button, no multi-step exit.

**Ceremony tiers.**
- **Common/Uncommon completions** (the bulk of everyday check-offs): a
  compact, non-modal "toast" style confirmation — inline, doesn't take
  over the screen, resolves in under a second, keeps the user in flow.
  This is what makes repeat use sustainable.
- **Rare/Epic/Legendary, or any level-up (of either kind):** a brief
  full-screen takeover with more visual weight (subtle glow/particle,
  richer color treatment, a distinct sound), because these are
  genuinely infrequent and the constitution explicitly asks for
  disproportionate care here. Still tap-anywhere-dismissible, still
  well under a few seconds if the user chooses to skip through it.

**Batch/multi-unlock handling.** Onboarding's retrospective import, or a
future integration sync that lands several completions at once, must
never trigger N sequential full ceremonies back to back — that's
ceremony fatigue, not celebration. Only a completion the user personally
triggers in the moment (tapping Mark Complete themselves, in this
session) gets the full unlock sequence described above. Batch-imported
completions are represented instead by the calmer aggregate treatments
already described (onboarding's Profile Reveal screen; a future
"X achievements added" summary for integrations) — never by looping this
sequence.

**Sound.** Optional, short, on a system-respecting channel (silent
switch honored); one light chime for standard completions, a distinct
richer chime for level-ups/Legendary tier. All information is also
conveyed visually — sound is never required to understand what happened.

**Reduce Motion / Reduce Transparency.** The full-screen tier becomes a
simple static reveal or crossfade — no particles. The counting-up XP
number can resolve instantly rather than animating through intermediate
values. Haptics are unaffected by Reduce Motion (separate system
setting) and continue to carry the "this registered" feedback for users
who've turned animation down.

**Deliberately NOT part of the unlock moment:**
- Ads or upsell of any kind.
- A forced "share this" prompt — sharing is offered later as a secondary
  action on the settled Completed screen, never inserted into the
  ceremony itself.
- "What's next" recommendations crammed into the same screen — the
  unlock stays singularly about the accomplishment just made; discovery
  of the next thing belongs back on Home/Discover.
- Comparison to other users, friends' times, or leaderboard movement in
  the moment of completion.
- Multiple competing calls to action.

---

## 4. Profile

Profile is the character sheet: "who am I, based on what I've actually
done." Per the constitution's social philosophy this is **profile-first,
not feed-first** — no activity feed, no comment threads, no algorithmic
timeline (PD-003). At MVP there are no friends, so the Profile tab only
ever shows **the signed-in user's own profile** — viewing another user's
profile isn't a concept that exists yet.

### Primary user intent

Unlike the other three screens, Profile doesn't converge on one action —
it's inherently browse-and-reflect, and that's deliberate, not a gap in
the spec:

- **Casual user:** a quick glance at overall level and the trophy case —
  a moment of "look what I've done" — then leave. No deeper intent
  required.
- **Power user:** the entry point into everything the constitution calls
  "deep system" — full quest management, category-by-category progress,
  stat charts, complete history. Profile is where the app's depth lives,
  precisely so Home doesn't have to carry it.

Both users load the same screen. The casual user's version is short
because their data is short — not because anything is hidden from them.

### Structure (top to bottom, one screen, no dashboard grid)

```
┌───────────────────────────────┐
│  [avatar]  Jordan               │
│  Level 12 · 4,780 lifetime XP  │
│  ▓▓▓▓▓▓▓▓░░  620 / 850 to Lv 13│
├───────────────────────────────┤
│  TROPHY CASE            Edit → │
│  [Rainier] [Grad] [7 countries]…│
├───────────────────────────────┤
│  CATEGORY LEVELS               │
│  Adventure   Lv 9   ▓▓▓▓▓▓▓░░  │
│  Fitness     Lv 7   ▓▓▓▓▓░░░░  │
│  Travel      Lv 6   ▓▓▓▓░░░░░  │
│  Education   Lv 5   ▓▓▓░░░░░░  │
│           Show all categories →│
├───────────────────────────────┤
│  QUESTS   3 Main · 4 Side · 11 Backlog │
│  • Sub-25 5K              62%  │
│  • Save $5,000             40% │
│           View all quests →    │
├───────────────────────────────┤
│  STATS                         │
│  Fastest 5K: 24:12   Countries: 9│
│           View all stats →     │
├───────────────────────────────┤
│  RARE ACHIEVEMENTS             │
│  [Epic · Ironman] [Rare · Marathon]│
├───────────────────────────────┤
│  COMPLETED              142 total│
│  ✓ Ran a 10K · 2 days ago      │
│  ✓ Visited Portugal · 1 wk ago │
│           View full history →  │
└───────────────────────────────┘
```

1. **Identity header.** Avatar, display name, Overall Level (large — the
   same visual weight Home gives it), a within-level progress bar, and
   **lifetime XP total spelled out** ("4,780 lifetime XP"). This is the
   one place the raw lifetime number gets shown prominently — Home
   deliberately withholds it (§2) so it doesn't compete with "what's next
   today."
2. **Trophy Case.** The emotional centerpiece — see §4a. Sits directly
   under the header because it's the most human, least numeric part of
   the screen, and should be the first thing a visitor's eye lands on
   once profiles are ever shown to anyone else.
3. **Category Levels.** The literal "character sheet" the constitution
   names. See §4b for the exact inline/expand rule — this is the
   resolution to the open question this doc previously flagged.
4. **Quests.** A compact summary (slot counts + a couple of the
   highest-priority active quests), not the full Main/Side/Backlog list.
   `View all quests` opens the dedicated Full Quest List screen (§4c) —
   the same destination Home's `See all quests` link (§2) points to.
5. **Stats.** A small, user-curated set of featured stats — mirrors the
   trophy case's curation model, not an auto-generated dashboard. `View
   all stats` opens deeper analytics (§4d).
6. **Rare Achievements.** System-curated (not user-picked, unlike the
   trophy case) — automatically surfaces the user's own Rare/Epic/
   Legendary completions. See §4e.
7. **Completed history.** Most recent handful inline, `View full history`
   opens the searchable/filterable complete list. See §4e.

### Primary action

There isn't a single forced primary action, and that's a deliberate
difference from the other three screens rather than an omission — Profile
is a read-first surface. If forced to name the closest thing to one, it's
whatever drill-in a given user actually wants (`View all quests` is the
most forward-looking, action-oriented link on the screen), but no visual
treatment pushes the user toward any one of them. A brand-new/empty
profile is the one exception — see Empty state.

### Secondary actions

`Edit trophy case`, `Edit selected stats`, `Show all categories`, `View
all quests`, `View all stats`, `View full history`, tapping any trophy
card / category row / quest / stat / history item to open its underlying
detail screen, and a settings entry point (gear icon, top-right of the
header) for account management — out of this doc's detailed scope except
where it intersects privacy (§4f).

### Empty state

Two distinct cases, handled differently on purpose:

- **Fresh from onboarding.** Every module already has *something* (a
  trophy the user was prompted to pick during onboarding reveal, at least
  one touched category, starter quests, an imported completion or two).
  Modules render normally, just short. The Stats module is the one
  legitimate exception — onboarding doesn't ask the user to pick featured
  stats, so it shows a single inline prompt: `Pick stats to feature →`.
- **User explicitly skipped onboarding (`Skip for now`, §1).** Every
  module would independently be empty. Rather than stacking five separate
  "nothing here yet" prompts — which reads as broken, not inviting — the
  whole screen collapses into **one consolidated empty state**: header
  shows Level 1 / 0 XP honestly, and below it a single card: `Nothing
  here yet — let's fix that` with one CTA, `Build my profile`, that
  re-enters the onboarding triage deck (§1). No module scaffolding
  (empty trophy row, empty category list, etc.) renders underneath it —
  showing five sad empty boxes is worse than showing one clear next step.

### Populated state

As diagrammed above. A profile that's several months old settles into a
steady state where every module has real content and the "show
all"/"view all" links are actually doing work (hiding real depth) rather
than being decorative.

### Edge cases

- **User active in all 10 categories for years.** Category module shows
  its 6-tile cap plus `Show all categories`; nothing about the screen's
  shape changes for this user versus a brand-new one — this is the
  load-bearing invariant that keeps Profile's *default* view identical in
  size for casual and power users (same principle Home already commits
  to in §2).
- **Trophy case, stats, or category selections reference an achievement
  the user later hides** (`isHiddenFromProfile = true`, per
  `docs/domain-model.md` §1.2). A hidden completed achievement is
  automatically pulled from the trophy case and rare-achievements strip
  if it was featured there — a hidden item can never still appear
  elsewhere on the same profile it's hidden from. The user is warned at
  the moment of hiding if it would remove something currently featured
  ("This is in your trophy case — hiding it will remove it from there
  too. Continue?").
- **A user-created achievement is later edited or deleted** by its
  creator. If it's referenced in the trophy case or featured stats, it's
  removed from those slots gracefully (slot becomes an empty "+" rather
  than a broken reference); history entries persist since completion
  history is permanent per the constitution.
- **Very long display name.** Truncates in the header; never pushes the
  level/XP line off-screen.
- **Multi-year power user's Completed History.** Hundreds of entries —
  the inline module still only ever shows the most recent handful; the
  full-history screen (§4e) is where pagination/search/filter live, never
  the Profile screen itself.

### Accessibility

- Every module is a distinct VoiceOver heading, read in the same
  top-to-bottom order sighted users see, so a screen-reader user can jump
  module-to-module via the rotor instead of swiping through the entire
  screen linearly.
- Horizontal scrolling collections (Trophy Case, Rare Achievements) use
  standard iOS scrollable-container semantics — each card is its own
  accessibility element (name, one-line context, date), never one
  flattened image described as "trophy case, image."
- Dynamic Type: category level rows, stat tiles, and trophy cards reflow
  (stack rather than clip) at larger sizes; at extreme sizes the category
  module and stats module may show fewer items per screen before
  scrolling, never truncated numbers.
- Level, XP, and category progress are exposed as spoken values, never
  conveyed by bar fill or color alone (same rule as Home, §2).
- Rarity badges on the Rare Achievements strip pair an icon/label with
  color, consistent with Achievement Detail (§3).
- All module-header links (`Show all`, `View all…`, `Edit…`) are ≥44pt
  tap targets.

### Deliberately NOT shown on Profile

- Other users' profiles, a friends list, or any comparison surface —
  doesn't exist yet, and even once it does, belongs to a
  leaderboard/friends surface, not folded into this screen.
- An activity feed, comments, likes, or any feed-style content (PD-003).
- All 10 categories shown flatly with equal weight, or fake "Level 1"
  badges on categories the user has never touched — see §4b.
- Full interactive charts inline — only single curated numbers (Stats
  module) with a drill-in; the chart-heavy view is a separate screen
  (§4d).
- Ads or upsell of any kind.
- A public/private toggle that doesn't yet do anything — see §4f for why
  this is a deliberate omission, not an oversight.
- An auto-generated "highlights" reel presented in place of, or blended
  with, the user's own trophy case picks — the system may suggest
  candidates when the user is curating (§4a), but never silently
  overrides what they've chosen.
- Every completed achievement ever, in one scroll — only a recent handful
  inline, full list behind `View full history`.
- Streak counters, "last active" timestamps, or any guilt/urgency
  messaging.

---

### 4a. Trophy Case

The constitution is explicit that this is user-curated, not
auto-generated, and "does not need to be the achievements worth the most
XP" — it should read as a small, personal set of mementos, not a badge
shelf. Visual treatment matters here more than almost anywhere else in
the app outside the unlock moment itself.

- **Presentation.** A horizontal row of individually-styled cards —
  closer to a framed photo/plaque than a generic achievement badge:
  achievement name, one short line of personal context if the user added
  one (optional — reuses the "Add note" field from Achievement Detail,
  §3), and the completion date. Deliberately a different card shape/style
  from ordinary achievement list rows elsewhere in the app, so it reads
  as "the highlight reel" at a glance rather than blending into routine
  UI.
- **Cap: up to 6 slots.** Chosen to keep it genuinely small (per the
  constitution's own wording) while comfortably fitting the constitution's
  own worked onboarding example (5 touched categories) with one slot of
  headroom; a tunable constant, not a hard product truth.
- **Order is user-controlled** (drag to reorder), not chronological or
  XP-sorted by default — sequencing is part of how this becomes "a
  miniature autobiography," and that's the user's authorship, not the
  system's.
- **Editing.** `Edit trophy case` opens a searchable picker over the
  user's completed achievements (search matters here for power users with
  a long history); tapping a completed slot removes it; an empty slot
  under the cap shows a `+` affordance. The picker may lightly suggest
  candidates (e.g., the user's rarest completions, or ones they added a
  note to) as a starting point for a new/undecided user, but selection is
  always a manual, one-at-a-time confirm — never auto-populated on the
  user's behalf.
- **Reachable from two places:** here, and as `Add to Trophy Case` on a
  completed Achievement Detail screen's overflow menu (§3) — the natural
  moment to add something is right after completing it.
- **Empty state.** A single prompt card in the row — `Pick your first
  trophy →` — opens the same picker. Not a barren empty rectangle with
  floating instructions.

### 4b. Category Levels — resolving the depth question

This section directly resolves the item this doc previously flagged as
open: *"Category level list depth in Profile (how many of the up-to-10
categories show by default vs. behind a 'show all')."*

Per `docs/domain-model.md` §2, all 10 categories exist as first-class
values from day one, but only 6 have seeded built-in content at MVP; the
other 4 are "defined but empty" (no curated library yet, but users can
self-create achievements in them immediately). **The profile must not
expose that seeded/unseeded distinction to the user at all** — it's a
content-curation implementation detail, not something a user should have
to understand. What the profile *does* need to distinguish is simply:
has this user done anything in this category, or not.

**Rule:**

- A category is **active** if it has any XP > 0 (i.e., the user has at
  least one completed achievement there, seeded or self-created — doesn't
  matter which).
- Inline on Profile, show **all active categories, sorted by level
  descending (ties broken by XP), capped at 6.** If the user has 6 or
  fewer active categories, every one of them shows inline — nothing is
  artificially held back behind "Show all" for a normal early user. If
  they have more than 6, the top 6 show inline and the rest sit behind
  `Show all categories`.
- **Dormant categories (0 XP) never appear inline, full stop** — not as
  "Level 1," not greyed out in the main list. Showing a category the user
  has never touched at "Level 1" would misrepresent activity as
  accomplishment (level 1 is XP ≥ 0's floor, not a real milestone) and
  would make an early profile look cluttered with categories that mean
  nothing yet.
- Dormant categories only appear inside the expanded `Show all
  categories` view, visually de-emphasized (muted color, no progress
  bar), labeled **"Not started"** rather than a level number, and listed
  after all active ones, sorted alphabetically (no meaningful basis to
  rank two categories that are both at zero).

**Why cap at 6, not some other number:** it matches the trophy case's cap
(both express "a small, curated, character-defining set," which is the
whole point of a character sheet), and it comfortably covers the
constitution's own worked onboarding example (Fitness, Travel, Education,
Skills, Experiences = 5 touched categories) without immediately forcing a
new user behind an extra tap. A user who's only touched 2–3 categories
sees exactly 2–3 tiles — never padded with zeros to look fuller than it
is.

### 4c. Full Quest List (Main / Side / Backlog)

This is the destination for both Home's `See all quests` link (§2) and
Profile's `View all quests` link — one canonical screen, two entry
points, so the full list is never duplicated in two places with two
different truths.

- **Three clearly labeled sections**, in this order: **Main Quests**
  (always shows exactly 3 rows — filled slots plus an explicit empty-slot
  `+` affordance for unused ones, so the 3-slot structure itself is
  always visible, not just implied), **Side Quests** (same pattern, cap
  5), **Backlog** (unlimited, plain reverse-chronological-by-added list
  by default).
- Tapping any quest opens its Achievement Detail screen (§3) — that
  screen remains the single source of truth for `Mark Complete` / `Log
  Progress` / `Pause` / `Abandon`; this list is for **overview and
  triage**, not a second place those actions live. A light swipe action
  (e.g., swipe to pause) is an acceptable accelerator, same rule as
  onboarding's swipe-plus-button pattern (§1) — never the only path.
- **Manually promoting/demoting** a quest (e.g., moving a Side Quest into
  a full Main track) triggers the same three-way choice specified in
  `docs/domain-model.md` §6 (demote something else / add as Side instead
  / cancel) — never a silent overwrite, regardless of whether the
  transition was triggered from here or from Achievement Detail.
- **Backlog empty state:** a single prompt, `Browse Discover for more
  quests →`, closing the loop back into the discovery surface rather than
  leaving a dead end.
- **Power-user affordance, off by default:** a filter/sort control
  (by category, by recently added) sits behind a small icon in the
  Backlog header — collapsed, not shown expanded, so a casual user with 4
  backlog items never sees a filter bar they don't need.

### 4d. Selected Stats & the deeper Charts screen

- **Selected Stats module (this screen):** a small, user-curated set of
  featured stats (e.g., "Fastest 5K: 24:12," "Countries: 9," "Longest
  run: 14 mi") — plain label-and-value tiles, no charts, no auto-populated
  dashboard of every stat the app happens to track. Curation model
  mirrors the trophy case: `Edit selected stats` opens a picker over the
  stats the user has any data for; nothing is featured without the user
  choosing it.
- **`View all stats`** opens a dedicated Charts/Analytics screen covering
  the constitution's full list (XP over time, achievements over time,
  category distribution, completion rate, personal-record history,
  rarity distribution, quest completion, seasonal comparisons, friend
  comparison once friends exist, achievement calendar, category level
  changes). **That screen's detailed layout is intentionally out of scope
  for this pass** — it deserves its own dedicated wireframe given how
  much surface area it covers (flagged in Open Questions below) — but its
  role from Profile's perspective is exactly the "progressive reveal"
  boundary: a casual user never has to open it, and nothing on the
  default Profile view depends on it existing.

### 4e. Completed History & Rare Achievements

Two related but distinct modules — don't merge them:

- **Completed History** is the user's own complete record: chronological,
  permanent (per the constitution, completions stay in history unless the
  user explicitly hides or undoes them), and comprehensive. Inline on
  Profile: most recent 3–5 entries. `View full history` opens the
  complete searchable/filterable list — filters (category, rarity, date
  range, verification level) live behind a single filter icon, collapsed
  by default, so the base experience is a plain reverse-chronological
  list, not a spreadsheet-style filter bar shown up front.
- **Rare Achievements** is a **system-curated** showcase — automatically
  populated with the user's Rare/Epic/Legendary-tier completions (per
  `docs/domain-model.md` §5's rarity labels), contrasted deliberately with
  the trophy case's manual curation. Visually smaller/lighter-weight
  cards than the trophy case's "plaque" treatment, so the two don't
  compete for the same visual register — trophy case says "this mattered
  to me," rare achievements says "this is objectively uncommon." If the
  user has zero Rare-or-above completions, the module is **hidden
  entirely**, not shown empty (same pattern Home uses for its Recent
  module, §2).
- Both modules respect `isHiddenFromProfile` — a hidden completed
  achievement never appears in either list, consistent with §4 Edge
  cases above.

### 4f. Visibility & privacy model

The constitution says "users should control what is public," but at MVP
there are no friends and no viewers other than the user themselves — a
profile-level public/private switch would be a real setting with zero
possible effect, which is exactly the "don't present a setting that does
nothing yet" trap this task called out. Two things are true and real
today; one thing is deliberately deferred:

- **Real today — per-item hiding.** `isHiddenFromProfile`
  (`docs/domain-model.md` §1.2) is a genuine, working control: a
  completed achievement stays permanently in the user's private history
  and its XP stands, but it can be excluded from every profile-facing
  surface (trophy case eligibility, rare-achievements strip, completed
  history). This is useful *today*, with zero viewers, purely as personal
  curation — and it's also the exact mechanism that will matter once
  profiles become visible to others, so nothing about it needs to change
  when Friends ships.
- **Real today — explicit outbound Share.** The `Share` action on a
  completed Achievement Detail screen (§3) generates a shareable card for
  *one* achievement, sent outside the app via the system share sheet.
  This is the only sense in which anything on this profile is "public"
  right now: a deliberate, one-item-at-a-time, user-initiated act, never
  an ambient or discoverable profile page. It requires no friends graph
  to be meaningful.
- **Deferred — a profile-level public/private toggle.** Not built, and
  **not shown in the UI at MVP.** `app-engineer` should add the
  structural data field now (a `profileVisibility` value, defaulting to
  private) so no migration is needed later, but no toggle renders on
  Profile or in settings until there's an actual audience (Friends,
  `BACKLOG.md` LATER) for it to control. Shipping a visible-but-inert
  toggle would be worse than shipping none — it implies a feature exists
  that doesn't.

This is a privacy-adjacent decision per `CLAUDE.md`'s working agreements
("escalate anything that materially changes... privacy") — flagged for
the founder in Open Questions below, though the recommendation above is
the one I'd ship absent objection.

---

## Open questions

For the founder / for coordination with `product-designer` and
`app-engineer`:

1. **Quick-add affordance.** Home has no persistent "+" for logging a
   win or adding a goal outside the modules described — is that
   acceptable friction, or does the founder want a fast global capture
   action (e.g. "I just did something not on my list") even before quest
   creation is fully speced? Leaning no for MVP (keeps Home's fixed
   four-module shape intact) but flagging it as a real tradeoff.
2. **Starter-quest auto-selection logic** on the onboarding Reveal screen
   (which 3 of the user's "Want to do" picks become default Main
   Quests) is left to `product-designer` — needs a concrete rule before
   `app-engineer` builds it.
3. **Rarity data cold-start — resolved.** `docs/domain-model.md` §5
   confirms this: seed content carries a `provisionalRarity` label used
   only for discovery-lane sorting, never shown to users as a fake
   statistic; real computed rarity (with an actual "X% of users"
   percentage) only replaces it once an achievement has 30+ distinct
   completions. Below that threshold — true for nearly everything at
   launch — the Detail screen and unlock ceremony should show the
   provisional label plain (e.g. "Uncommon"), with no percentage
   attached, rather than the "34% of users" framing this doc originally
   sketched.
4. **Category level list depth in Profile — resolved.** §4b above settles
   this: only categories with any real XP ("active") show inline, capped
   at 6 and ranked by level; categories with zero XP never appear inline
   at all (not even as "Level 1") and only show, de-emphasized as "Not
   started," inside `Show all categories`.
5. **Trophy case (§4a) and category-module (§4b) caps of 6** are
   calibrated design guesses, not tested numbers — worth a gut-check once
   real profiles exist, same caveat `product-designer` already attached to
   the XP curve in `docs/domain-model.md` §7.
6. **Profile-level public/private toggle (§4f) — deliberately not built
   or shown at MVP,** in favor of two things that are real today
   (per-item hide, one-off Share) plus a structural-only DB field for
   `app-engineer` to add now. Flagging for the founder specifically
   because it's a privacy-adjacent call: confirm this reads as "sensible
   sequencing" rather than "a feature quietly missing," and that a
   silent, no-UI placeholder field is the right way to avoid shipping an
   inert toggle.
7. **The Charts/Analytics screen referenced from Profile's `View all
   stats`** (§4d) is real scope but was intentionally not wireframed in
   this pass — it covers a lot of surface area (the constitution's full
   analytics list) and deserves its own dedicated pass rather than being
   squeezed in as a subsection here. Needed before `app-engineer` builds
   that screen.
