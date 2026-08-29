# Wireframes — Onboarding, Home, Achievement Detail, Profile, Charts & Analytics

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

## 5. Charts & Analytics

This is the destination for Profile's `View all stats` link (§4d) — the
one screen in this doc that is **deliberately power-user territory**, not
a "simple surface" screen. The constitution says it directly: "A casual
user should never need to look at these. A power user should be able to
spend significant time exploring them." Every other screen in this doc is
graded on how little a casual user has to see; this one is graded on how
much a power user finds worth staying for, subject to exactly one
constraint carried over from the rest of the app — **nothing here is ever
required to understand the rest of the product.** A user who never opens
this screen loses no comprehension of their level, quests, or profile.

Reached from exactly one place at MVP: Profile → `View all stats`. There
is no tab-bar entry and no other entry point — this keeps the three-tab
IA (§ intro) intact and keeps this screen firmly one deliberate tap below
the surfaces a casual user actually lives in.

### Primary user intent

- **Casual user (the expected case: never opens this screen).** Nothing
  is lost. This is the explicit design bet the whole screen makes.
- **Casual user who taps in out of curiosity.** Should be able to glance
  at the first section or two, understand it immediately (plain charts,
  plain labels, no jargon), and leave without feeling they've entered a
  spreadsheet or a "real" analytics product. Nothing above the fold should
  intimidate.
- **Power user.** Wants to go deep: look at trends over years, compare
  categories, find personal records, see rarity, and generally treat this
  as their own life's dashboard. This user should be able to spend real
  time here and keep finding legible, well-organized structure rather
  than a wall of numbers.

### Structure decision: one continuous scroll, not tabs

Chosen over a tabbed/segmented-control screen for three reasons:

1. **Discovery over navigation.** A power user exploring "significant
   time" (constitution's own phrase) benefits from serendipitously
   scrolling past a section they weren't looking for (e.g., landing on
   Achievement Calendar while looking for XP Over Time) the way a
   Steam/Xbox stats page works. Tabs hide everything except the active
   tab, which optimizes for someone who already knows exactly what they
   want — the wrong optimization for a screen whose whole point is
   exploration.
2. **No hidden state to lose.** Tabs mean scroll position and range
   selection reset or fork per tab, and "which tab was I on" becomes a
   thing to restore on return. A single scroll has one position, one set
   of controls, and behaves predictably with the back button — simpler to
   build and simpler to reason about, consistent with the agent brief's
   "avoid... cluttered dashboards."
3. **It still satisfies "individually titled sections a casual visitor can
   parse quickly."** Each section is its own titled card with its own
   internal logic — a user can read exactly one card and stop, exactly
   like reading one paragraph of a long article, without needing tab
   context to make sense of it.

The one navigation aid that *is* included: a slim, sticky **jump-chip
row** directly under the range control (see diagram) — horizontally
scrollable pill buttons ("XP," "Activity," "Categories," "Records,"
"Rarity," "Quests," "Seasons") that smooth-scroll the page to that
section. This is a scroll-position shortcut, not a tab switch — nothing
is hidden, nothing unmounts, it just saves a returning power user from
scrolling past ten cards to reach the one they check weekly.

A second, **global sticky range control** (`30D · 90D · 1Y · All`) sits at
the very top, under the nav bar, and governs every time-series section at
once (XP Over Time, Achievements Completed Over Time, Achievement
Calendar, Category Level Changes, Quest Completion trend). One control
instead of eleven separate per-chart pickers is the load-bearing
simplicity decision on an otherwise information-dense screen — sections
that aren't inherently time-ranged (Category Distribution, Rarity
Distribution, Completion Rate, Personal Records) ignore it and show
current/lifetime standing instead, and say so in their subtitle so it's
never ambiguous which sections respond to the control.

**No dashboard customization in v1** — section set and order are fixed,
not user-configurable (no drag-to-reorder, no show/hide toggle per
section). This is a deliberate constraint even on the power-user screen:
richness comes from depth *within* each section, not from turning the
screen itself into a configuration surface — consistent with the agent
brief's "avoid... endless configuration screens."

### Visual hierarchy (top to bottom)

```
┌───────────────────────────────┐
│  ← Charts & Analytics          │
├───────────────────────────────┤
│  30D   90D   [1Y]   All        │  ← sticky global range control
├───────────────────────────────┤
│  XP · Activity · Categories ›  │  ← sticky jump-chip row (scrolls)
├───────────────────────────────┤
│  XP OVER TIME          Σ / Δ   │
│     ╱‾╲___╱‾‾‾‾‾╱               │
│  6,140 XP this year             │
├───────────────────────────────┤
│  ACHIEVEMENTS COMPLETED         │
│  ▁▂▃▅▂▇▃▂▅▆▃▂                   │
│  38 completed this year         │
├───────────────────────────────┤
│  ACHIEVEMENT CALENDAR           │
│  ▪▪▫▪▫▫▪▫▪▪▫▪▫▪▫▪▪▫▪▫▪          │
├───────────────────────────────┤
│  CATEGORY LEVEL CHANGES         │
│  Adventure ╱‾╱‾‾  Fitness ╱‾    │
├───────────────────────────────┤
│  CATEGORY DISTRIBUTION  · now   │
│  ◔  Adventure 34% · Fitness 22%│
├───────────────────────────────┤
│  COMPLETION RATE        · now   │
│  82% · 38 of 46 ever started    │
├───────────────────────────────┤
│  ACHIEVEMENT RARITY     · now   │
│  ▓▓▓▓░░░  mostly Provisional    │
├───────────────────────────────┤
│  QUEST COMPLETION               │
│  Main ●●● · Side ●●●○○ · chains │
├───────────────────────────────┤
│  PERSONAL RECORDS   Coming soon │
├───────────────────────────────┤
│  SEASONAL COMPARISON Coming soon│
└───────────────────────────────┘
   (Friend Comparison does not
    render at all — see §5b)
```

Every card follows the same internal layout: **title** (top-left) →
**scope subtitle** (e.g. "Last 12 months" or "· now", top-right, always
present so a user never has to guess whether the global range applies) →
**chart** → **one-line plain-language takeaway** beneath it (e.g. "6,140
XP this year, up from 3,900 last year") so the chart is never presented
without a legible headline number for a reader who wants the gist without
parsing the visualization itself.

### Primary action

Same as Profile (§4): there isn't one forced primary action, and that's
intentional — this is a read-and-explore screen, not a task screen. The
closest thing to a primary action is whichever card a given user came to
check, and the range control / jump chips exist purely to get there
faster, not to funnel toward a specific outcome.

### Secondary actions

- Tap the range control to change scope for all time-series sections at
  once.
- Tap a jump chip to scroll to that section.
- Tap any time-series card (XP Over Time, Achievements Completed Over
  Time, Achievement Calendar, Category Level Changes) to open a focused,
  full-screen version of just that chart — finer time granularity,
  tap-to-inspect individual data points (e.g., tapping a bump in XP Over
  Time shows "Sub-25 5K · +250 XP · Aug 14"), and a `View as table` toggle
  that exists specifically for the accessibility case described below,
  not buried as a hidden feature.
- Inline per-card toggles where a real second view is useful and cheap:
  XP Over Time (`Σ` cumulative vs. `Δ` per-period), Achievements Completed
  Over Time (stacked-by-category on/off).
- Tap a category in Category Distribution or Category Level Changes to
  isolate/highlight just that category's line or slice (dims the rest);
  tap again to restore all.

### Empty state

There is a meaningful difference between "this user has almost no data
yet" and "this feature doesn't exist for anyone yet," and the screen
treats them differently on purpose (see §5b for the full reasoning):

- **New/light user, sparse but real data.** Every section that has *any*
  underlying concept still renders, with a calm, specific empty/sparse
  message in place of a chart that would otherwise be a flat, discouraging
  line at zero — e.g. XP Over Time shows "Keep completing achievements to
  see your trend" instead of a flat 0 line; Achievement Calendar shows an
  all-empty grid with a single caption rather than looking broken. This
  matches the principle that a deliberately-entered power-user screen
  should never look buggy to a new visitor, even though it will look
  short.
- **Features with zero product capability today (Friend Comparison).**
  Hidden entirely — not rendered, not teased. See §5b for why this is
  categorically different from "sparse data."
- **Features that are promised but schema-blocked (Personal Records,
  Seasonal Comparisons).** Shown as a small, honest, non-interactive
  "Coming soon" card — title and one sentence, no fake chart, no
  fabricated numbers. See §5c for why these get a placeholder while
  Friend Comparison doesn't.

### Populated state

As diagrammed above — a multi-year power user scrolling through a fully
populated version of every ready section, each with real trend lines,
real distributions, and legible one-line takeaways.

### Edge cases

- **Zero data in the selected range** (e.g., a new account with `1Y`
  selected). Per-section empty copy as above, not a blank/broken chart —
  applies per-section, independent of whether other sections in the same
  scroll have data.
- **Very long history at `All` range.** Bucket granularity (daily → weekly
  → monthly) must adapt automatically to the span so a multi-year line
  chart never renders as an unreadable wall of daily noise. This is a
  chart-rendering rule owned jointly with `app-engineer`, but the UX rule
  — granularity adapts to range, never fixed at "daily" regardless of span
  — belongs here.
- **An "Undo completion" reverses a past data point** (`domain-model.md`
  §1.4/§3.4). The XP ledger reversal must be reflected in every chart that
  derived from it — the affected point/bar shrinks or disappears rather
  than leaving a stale bump that no longer matches the user's real
  history. Tapping a reversed point in the drill-in view can show
  "Undone — no longer counted" for transparency rather than just quietly
  vanishing.
- **A quest-chain rung is auto-completed retroactively** (rungs 1–3
  marked `completed` because the user directly completed rung 4, per
  `domain-model.md` §4.4). Quest Completion and the Achievement Calendar
  must reflect all of them at their real (backfilled) completion
  timestamps, not show a confusing gap.
- **`isHiddenFromProfile` items — resolved deliberately differently from
  Profile.** Trophy Case, Rare Achievements, and Completed History (§4)
  all *exclude* hidden achievements because those are public-facing
  showcase surfaces. Charts & Analytics is never a public-facing surface
  (there is no profile-visibility concept applied to this screen — see
  §4f) — it is the user's own private view of their own true history. It
  therefore **includes hidden achievements' data in every chart**,
  otherwise "XP over time" summed across this screen would silently fail
  to match the lifetime XP total shown at the top of the user's own
  Profile, which would read as a bug, not a feature. Worth stating
  explicitly since it's the one place this doc treats hidden items
  differently than elsewhere.
- **Very small absolute numbers** (e.g., one completion this month). Axis
  scaling stays calm and consistent rather than auto-zooming to make "1"
  visually dominate the card — a real product habit worth avoiding, since
  exaggerating small numbers reads as manipulative gamification, not
  honest reporting.
- **A single achievement contributes to multiple sections at once** (e.g.
  a Legendary-rarity chain-rung completion shows up in XP Over Time,
  Achievement Calendar, Rarity Distribution, and Quest Completion
  simultaneously). No section needs to cross-reference this explicitly;
  each is independently correct because all of them read from the same
  underlying instance/ledger data, not from each other.

### Accessibility

- **Every chart carries a text-equivalent, not just a visual one.**
  VoiceOver reads the one-line plain-language takeaway beneath each chart
  as that card's primary accessible description (e.g., "XP over time.
  6,140 XP this year, up from 3,900 last year"), and the `View as table`
  toggle available from every chart's drill-in view exposes the same
  series as an ordinary accessible list/table — charts are never the only
  way to access the underlying numbers.
- **Dynamic Type at very large sizes.** Chart canvases keep a sensible
  minimum size rather than being squeezed illegibly; card titles and
  takeaway text reflow normally. At the largest accessibility sizes, a
  card's chart may become horizontally scrollable within its own card
  rather than shrinking to unreadable, but it never pushes into the next
  card's space.
- **Color.** All charts use a color-blind-safe palette and pair every
  color-coded series (category lines, distribution slices) with a visible
  text label — never color as the only means of distinguishing series,
  consistent with every other screen in this doc.
- **Reduce Motion.** Line-drawing / counting-up entrance animations are
  replaced with the chart simply appearing in its final state; this is
  purely cosmetic and never removes information, since the same data is
  always available via the table view regardless of motion settings.
- **Tap targets.** Range-control segments, jump chips, and per-card
  toggles are all ≥44pt, same rule as every other screen in this doc.

### Deliberately NOT shown

- **No global leaderboards or public ranking.** Leaderboards are a
  separate, not-yet-designed surface (`BACKLOG.md` LATER) — if/when they
  ship, they get their own place, not a folded-in card here.
- **No monetization/upsell messaging**, even though the constitution
  lists "advanced analytics" and "enhanced historical analysis" as
  candidate premium areas. This screen intentionally does not gate
  anything by design — whether/how to gate any of it later is
  `monetization-growth`'s call layered on top afterward, not something
  baked into this wireframe (see Open Questions).
- **No dashboard-building/configuration step.** No "choose your widgets"
  setup wizard, no per-user rearranging — see the "no dashboard
  customization" decision above.
- **No fabricated or estimated data standing in for real data.** No
  interpolated points before real history exists, and no rarity
  percentage shown before an achievement crosses the 30-completion
  threshold (`domain-model.md` §5) — Rarity Distribution shows honest
  "mostly Provisional" framing rather than inventing precision the data
  doesn't support yet.
- **No comparison to a global "average user" aggregate**, even as a
  substitute for Friend Comparison. With a handful of total users any such
  average would be both statistically meaningless and potentially
  identifying (the same reasoning `domain-model.md` §5 already applied to
  raw rarity percentages) — this isn't a placeholder waiting for more
  users, it's a permanent design stance until there's a userbase large
  enough for an aggregate to mean anything and protect anonymity.
- **No streak or "days active in a row" chart.** Even framed neutrally as
  "analytics," this is the streak mechanic the constitution explicitly
  forbids — excluded categorically, not just deprioritized.
- **No "time spent in app" / session-count / open-frequency analytics.**
  The product is a scoreboard for real life, not a screen-time dashboard;
  surfacing app-usage metrics here would optimize for exactly the wrong
  thing per the Product Test ("are we rewarding accomplishment or merely
  app usage?").

---

### 5a. Section-by-section spec

Grouped for scannability within the single scroll (group labels are a
documentation convenience here, not rendered UI chrome — each card below
is still its own independently titled section on-screen, per the
"distinct, individually-titled sections" requirement).

**Group A — Progression over time** (all governed by the global range
control)

1. **XP Over Time.** Line/area chart; `Σ` cumulative lifetime XP or `Δ`
   XP earned per period (inline toggle). Tappable points show the
   achievement that granted that XP. *Ready to build* once the XP ledger
   table (`domain-model.md` §3.4) is confirmed to carry per-row timestamp
   and category — see §5c.
2. **Achievements Completed Over Time.** Bar chart, count per period,
   optional stacked-by-category. *Ready today* — derives directly from
   `UserAchievementInstance.completedAt`, no new schema.
3. **Achievement Calendar.** GitHub-contributions-style heatmap grid, one
   cell per day, shaded by completion count that day. *Ready today* —
   same source as #2. Deliberately **not** framed as a streak — no
   "current streak" number anywhere near it, just a density map of a
   life, on purpose (see Deliberately NOT shown above).
4. **Category Level Changes.** Multi-line chart, one line per **active**
   category only (reuses the exact "active = any XP > 0" rule from §4b,
   for consistency with Profile) — dormant categories never appear here
   either, same reasoning as §4b. Tap a legend entry to isolate its line.
   *Ready with the same ledger-timestamp dependency as #1*, plus a small
   coordination question: is "level as of date T" computed live from
   bucketed ledger totals, or from a periodic snapshot? Implementation
   choice for `app-engineer`; either is fine as long as it's consistent
   with the level formula in `domain-model.md` §3.3.

**Group B — Composition & distribution** (current standing, not
time-ranged — each card's subtitle says "· now" rather than a date range)

5. **Category Distribution.** Donut or horizontal-bar breakdown of
   lifetime XP share by category. *Ready today.*
6. **Completion Rate.** A single prominent percentage plus its
   denominator, e.g. "82% · 38 of 46 ever started." *Ready today*, but
   the exact formula needs one confirmation (see §5c) — proposed default:
   `completed ÷ (completed + abandoned-after-active + currently active)`,
   counted only over achievements that ever reached `active`. This
   deliberately excludes `interested`/backlog items that were never
   started (declining to pursue a mere idea from the backlog isn't a
   "failure" worth counting against the user) and excludes items still
   sitting at bare `discovered`.
7. **Achievement Rarity Distribution.** Simple bar/stack showing how many
   of the user's completions fall in each rarity tier. *Ready to build
   the UI today*, but the content itself will be thin for a long time by
   design, not by bug — per `domain-model.md` §5, almost everything shows
   `provisionalRarity` until an achievement crosses 30 distinct
   completions app-wide, so this chart should show tiers honestly labeled
   (including an explicit "Provisional" bucket) rather than implying more
   precision than the underlying data currently supports.

**Group C — Records & quests**

8. **Quest Completion.** Compact status view: Main/Side slot fill (●●●
   filled vs ○ empty, matching the Full Quest List's visual language from
   §4c) plus completion-rate-over-time for quests specifically, and a
   list of the user's quest chains with a rung-progress bar per chain
   (e.g. "5K Questline · 3 of 6"). *Ready today* — derives from
   `questSlotType`, `state`, `questChainId`, and `questChainPosition`, all
   already in `domain-model.md` §1.2.
9. **Personal Record History.** *No longer blocked on data modeling* —
   `docs/domain-model.md` §8 now specs a `Stat`/`StatEntry` entity pair
   with live-derived personal records and record-broken events. Still
   shown as "Coming soon" at MVP because the schema doesn't exist in any
   database yet (no Supabase project, `BACKLOG.md` NEXT) and this
   section's own drill-in layout (per-stat chart, record-broken markers)
   hasn't had its dedicated UX pass — see §5c for the updated readiness
   note.

**Group D — Comparative**

10. **Seasonal Comparisons.** *No longer blocked on data modeling* —
    `docs/domain-model.md` §9 defines season boundaries as fixed calendar
    quarters (no named seasons, no stored `Season` entity, no mutable
    season-score table) and specs this card as five on-demand aggregate
    queries over existing timestamped data. Still shown as "Coming soon"
    at MVP because no database exists yet to query — see §5c.
11. **Friend Comparison.** *Not rendered at all* at MVP — see §5b.

### 5b. Friend Comparison: why hidden entirely, not shown empty

The task of designing this screen requires one explicit call: what
happens to "friend comparison" when the user has zero friends, which is
100% of users today (Friends is `BACKLOG.md` LATER, with no schema, no
friends list anywhere else in the product).

**Decision: the section does not render at all.** Not a greyed-out card,
not an empty-state card, not a "coming soon" teaser. It is absent from
the scroll and absent from the jump-chip row, exactly as if it didn't
exist in this document's spec.

This is a different treatment than the two other "not ready" sections
(Personal Records, Seasonal Comparisons get an honest "Coming soon" card
— §5c), and the distinction is deliberate, not inconsistent:

- Personal Records and Seasonal Comparisons are **single-player concepts
  that already exist elsewhere in the product's vocabulary** (Profile's
  Stats module, Seasons as described narratively in the constitution) —
  they're promised, partially implied, and blocked purely on a data model
  that hasn't been designed yet. A "Coming soon" card is honest: the
  feature is real, just not built.
- Friend Comparison depends on an entire **social graph feature
  (Friends) that has zero presence anywhere in the app** — no friends
  list, no friend requests, no visibility model beyond the single-user
  case (`domain-model.md` has no friends schema at all; `docs/wireframes.md`
  §4f explicitly defers even the profile-visibility toggle). Teasing a
  comparison feature for a social system that doesn't exist anywhere else
  in the product would set an expectation the rest of the app can't back
  up yet, and deciding whether/how to tease upcoming social features at
  all is closer to a roadmap/marketing call than a screen-design one —
  not something this wireframe should silently decide by including a
  placeholder.

This mirrors the pattern already used elsewhere in this doc for
zero-data showcase modules (Home's Recent module when onboarding was
skipped, Profile's Rare Achievements with zero rare completions, §2/§4e)
— hide rather than show an empty box that reads as broken — applied here
for an even stronger reason: it isn't just empty, the underlying concept
doesn't exist in the product yet at all.

**When Friends ships** (per `BACKLOG.md` LATER), this section reappears
automatically with real content — but its actual design (head-to-head vs.
category-relative vs. something else, consistent with the constitution's
leaderboard priority of friends-first comparison) is explicitly **not**
speced here and needs a dedicated pass coordinated with `product-designer`
once Friends exists, the same way this whole screen needed its own pass
rather than being squeezed into the Profile doc.

### 5c. What's ready to build today vs. blocked — coordination flags

No dedicated analytics/stats data model has been speced anywhere yet
(`domain-model.md` only has "Life Statistics" as a loose narrative
concept, plus `progressValue` as a single current value on
`UserAchievementInstance` — not a time series). This section is explicit
about which parts of §5a can be built from what already exists in
`domain-model.md`, and which need real design work first — per this
task's instruction, none of that missing data model is invented here —
it's flagged back to `product-designer`/`app-engineer` instead.

**Ready to build now, no new schema:**
- Achievements Completed Over Time (#2)
- Achievement Calendar (#3)
- Category Distribution (#5)
- Achievement Rarity Distribution (#7) — UI ready; content will be
  naturally thin per `domain-model.md` §5, not a bug
- Quest Completion (#8)

**Ready to build now, confirmed against the live migration:**
- XP Over Time (#1) and Category Level Changes (#4) — the `xp_ledger`
  table already carries per-row `granted_at`, `category`, `amount`, and
  the achievement/instance reference (so a reversal can be matched and
  reflected — see Edge cases above). Confirmed directly against
  `backend/supabase/migrations/20260829000000_initial_schema.sql`, no
  schema change needed.

**Ready with a small, low-risk coordination item (not schema, a product
decision):**
- Completion Rate (#6) needs one product decision, not new schema: the
  exact formula. A default is proposed in §5a #6; needs
  `product-designer` sign-off before `app-engineer` builds the query.

**Product-design work now done — no longer blocked on a missing data
model, but still not renderable as more than a "Coming soon" card until
the schema is actually deployed:**
- **Personal Record History (#9).** `docs/domain-model.md` §8 now specs
  a `Stat` entity (user-scoped name/unit/comparison-direction) and a
  `StatEntry` history table, with the current personal record and
  "record broken" events both derived live from that history (no extra
  stored event table). Query pattern is specified; no new schema beyond
  those two tables. Remaining blockers: (1) no Supabase project exists
  yet to hold the tables at all (`BACKLOG.md` NEXT, same blocker as the
  rest of the schema), (2) this section's actual on-screen layout
  (per-stat drill-in, how record-broken moments are marked on a chart)
  still needs its own `ux-ui-designer` pass — §8 deliberately specs data
  only, not screen layout. Ships as "Coming soon" until both are done.
- **Seasonal Comparisons (#10).** `docs/domain-model.md` §9 resolves
  season boundaries as fixed Gregorian calendar quarters (Q1–Q4, chosen
  explicitly over named seasons like "Summer" for a global,
  hemisphere-agnostic userbase) with **no stored `Season` entity and no
  mutable season-score table** — every figure this card needs is an
  on-demand aggregate query over already-timestamped `xp_ledger` /
  `UserAchievementInstance` / `StatEntry` rows for the quarter's date
  range. Remaining blocker is the same as #9: no live database yet. A
  persisted, resettable season-score table is explicitly *not* needed for
  this card — §9 flags that as a separate, later need once
  Friends/Leaderboards are real.
- **Friend Comparison (#11).** Blocked on the entire Friends feature
  (`BACKLOG.md` LATER) — not rendered at all, per §5b.

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
   stats`** (§4d) — **resolved.** §5 above is that dedicated pass: one
   continuous scroll of individually-titled sections (not tabs — see §5
   for why), a single global range control, and an explicit readiness
   split (§5c) between sections `app-engineer` can build now and the two
   (Personal Records, Seasonal Comparisons) blocked on data model work
   `product-designer` hasn't done yet.
8. **Friend Comparison hidden entirely at MVP (§5b)** — for the founder:
   confirm this reads as the right call versus, say, a "coming soon"
   teaser. My reasoning is that teasing a social feature that has zero
   presence anywhere else in the app yet is closer to a
   roadmap/expectations call than a screen-design one, so I defaulted to
   "absent" rather than deciding that for you.
9. **Personal Record History and Seasonal Comparisons — resolved.**
   `docs/domain-model.md` §8 (`Stat`/`StatEntry`, live-derived personal
   records) and §9 (fixed calendar-quarter seasons, no stored `Season`
   entity, no mutable season-score table) now spec both entities. They
   remain "Coming soon" cards purely because no live database exists yet
   to hold the schema (`BACKLOG.md` NEXT) — see the updated §5a #9/#10
   and §5c.
10. **XP ledger column completeness — resolved.** The `xp_ledger` table in
    `backend/supabase/migrations/20260829000000_initial_schema.sql`
    already has everything #1/#4 need: `granted_at` (timestamp),
    `category`, `amount`, and both `achievement_definition_id` and
    `user_achievement_instance_id` (so a reversal, or a drill-in tap, can
    resolve back to the achievement that earned it). XP Over Time and
    Category Level Changes can query this table directly — no schema
    change needed, confirmed against the live migration rather than left
    open.
11. **Completion Rate's exact formula** (§5a #6) is given a proposed
    default (`completed ÷ (completed + abandoned-after-active +
    currently active)`, counted only over achievements that ever reached
    `active`) but needs `product-designer` sign-off before `app-engineer`
    builds the query against it.
12. **Advanced-analytics monetization.** The constitution lists "advanced
    analytics" and "enhanced historical analysis" as candidate premium
    areas, and this screen is exactly where that would apply if it ever
    does. §5 deliberately builds nothing gated and recommends no specific
    gating — that tradeoff belongs to `monetization-growth` to evaluate
    separately against user trust, not something this wireframe should
    decide by default.
