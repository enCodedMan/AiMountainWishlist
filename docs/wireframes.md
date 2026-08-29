# Wireframes — Onboarding, Home, Achievement Detail

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
4. **Category level list depth in Profile** (how many of the up-to-10
   categories show by default vs. behind a "show all") isn't speced
   here since Profile wasn't in scope for this milestone — will need its
   own wireframe pass before `app-engineer` builds it.
