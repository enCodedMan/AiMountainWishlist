# Life Achievement App — Product Constitution

This is the canonical source of truth for product philosophy, mechanics, and
scope decisions. Every agent working on this codebase should treat this
document as authoritative. When uncertain, return to this document rather
than improvising.

## Product Vision

We are building an iPhone-first application that turns real life into a
satisfying achievement and progression system.

The simplest description is:

Xbox/Steam-style achievements + RPG progression + a personal life dashboard.

The app should make accomplishing things in real life feel satisfying
without turning life into an exhausting productivity system.

The phone is the scoreboard.

The real game happens outside the app.

The product should encourage users to close the app and go live interesting
lives.

Android may come later. The initial product must be designed so future
Android development is practical.

## Founder Vision

The founder wants:

- Extremely low barrier to entry
- Comfortable, attractive, intuitive UI
- Satisfying achievement unlocks
- Life statistics
- XP
- Levels
- Category levels
- Goals
- Quest chains
- Charts
- Personal records
- Leaderboards
- Friends
- Achievement rarity
- A large built-in achievement library
- User-created achievements
- Potential AI-generated recommendations
- Optional achievement verification
- Potential integrations such as Strava
- Strong free product
- Optional premium functionality
- Monetization that does not annoy or exploit users

The product should work for both casual and obsessive users.

A casual user should be able to open the app occasionally, mark
accomplishments, track several goals, and enjoy watching their profile
develop.

A power user should be able to explore years of data, progression charts,
records, category levels, rarity statistics, quest chains, leaderboards,
and detailed life analytics.

Complexity should be available but never mandatory.

## Core Product Philosophy

### 1. Simple Surface, Deep System

A user should understand the basic product almost immediately.

The home experience should remain simple even if the underlying system
becomes sophisticated.

Never require users to configure complex dashboards, taxonomies, scoring
systems, or databases before receiving value.

Advanced functionality should reveal itself progressively.

### 2. The App Is a Scoreboard, Not the Game

We do not want users spending hours inside the application optimizing
imaginary numbers.

The product should reward real-world behavior rather than app usage.

Avoid mechanics where users earn meaningful progression merely by opening
the app repeatedly.

Avoid engagement metrics that reward screen time for its own sake.

A great session can last 20 seconds.

### 3. No Productivity Guilt

This is not another guilt-based habit tracker.

Users may:

- pause goals
- abandon goals
- change interests
- pursue seasonal interests
- take breaks

without losing lifetime accomplishments or being punished.

Avoid shame-based notifications.

Avoid aggressive streak mechanics that make users afraid of missing a day.

### 4. Finite Achievements Beat Endless Grinding

Achievements should represent meaningful accomplishments.

Examples:

- Run your first 5K
- Run a sub-20 5K
- Save $10,000
- Visit ten national parks
- Skydive
- Graduate college
- Build a piece of furniture
- Climb a 14er

Whenever possible, large ambitions should have intermediate achievements.

Example — 5K Questline:

First 5K → Sub-30 → Sub-27:30 → Sub-25 → Sub-22:30 → Sub-20

Large achievements should feel achievable through progression.

## Core Gameplay Loop

The primary loop is:

Discover → Choose → Progress → Complete → Celebrate → Level Up → Discover
Again

Or more fundamentally:

Live life → Make progress → Record or verify it → Receive satisfying
feedback → See how your life has developed → Find another worthwhile
challenge → Go live life

## Achievement System

Achievements are accomplishments.

Possible achievement states:

- Not discovered
- Discovered
- Interested
- Active
- Completed
- Paused
- Abandoned

Completed achievements remain permanently part of the user's history unless
manually removed.

Achievements may be:

- built-in
- user-created
- AI-generated
- automatically detected through integrations

Achievements may belong to quest chains.

## Quest System

A Quest is an achievement the user is currently pursuing.

Users may save unlimited future goals.

However, the interface should encourage a limited number of active goals.

Possible model:

- 3 Main Quests
- approximately 5 Side Quests
- unlimited Backlog / Someday goals

This limit exists to create focus, not to monetize slots.

Never charge users for additional goal slots.

## XP Philosophy

XP represents accomplishment.

XP must never become pay-to-win.

Users must never be able to directly purchase XP.

Premium subscriptions must never grant XP multipliers.

XP should primarily reflect:

- difficulty
- commitment
- meaningfulness
- rarity where appropriate

Exact XP balancing will evolve through testing.

Illustrative scale:

- Small experience: 10–50 XP
- Moderate achievement: 100–500 XP
- Major achievement: 500–2,500 XP
- Exceptional lifetime achievement: 2,500–10,000+ XP

XP values must remain psychologically understandable.

## Levels

Users have:

**Overall Level** — Represents total lifetime progression.

**Category Levels** — Users also progress independently in areas such as:

- Fitness
- Adventure
- Travel
- Money
- Career
- Education
- Skills
- Relationships
- Maker / Projects
- Experiences

Category levels create a real-life character sheet. Different users should
naturally develop very different profiles.

## Life Statistics

Achievements are discrete. Stats are continuous measurements.

Examples:

- Fitness: fastest mile, fastest 5K, longest run, bench press, pull-ups
- Adventure: mountains climbed, highest elevation, countries visited,
  national parks visited
- Money: savings, investments, net worth, passive income
- Learning: books read, certifications, degrees, languages

Users should only track stats they care about. The app must never demand
that users fill out dozens of irrelevant statistics.

Stats may automatically trigger achievement unlocks.

## Achievement Verification

Trust is the default. Verification is optional unless a particular
competitive environment requires otherwise.

Possible verification levels:

- **Self Reported** — User marks the achievement completed.
- **Evidence** — User attaches something such as a photo.
- **Verified** — A trusted integration verifies the achievement (e.g.
  Strava, Apple Health, future supported integrations).

Verification should increase credibility rather than create unnecessary
friction.

## Achievement Rarity

Achievements may display the percentage of users who have completed them.

Possible rarity labels: Common, Uncommon, Rare, Epic, Legendary.

Eventually rarity should primarily derive from real completion statistics
rather than arbitrary classification.

## Secret Achievements

The system may include hidden achievements that encourage exploration.

Examples:

- Complete achievements in every major category
- Complete 25 Side Quests
- Complete an unusually difficult achievement
- Complete five outdoor achievements
- Reach Level 10 in multiple categories

Secret achievements may be humorous. They should not manipulate users into
unhealthy behavior.

## Achievement Unlock Experience

Completing an achievement should feel excellent. This experience is one of
the most important pieces of the entire product.

An unlock may show: achievement name, XP earned, category XP, rarity,
level-up information, optional subtle animation, sound, and haptic
feedback.

The experience should feel premium and satisfying without becoming
annoying or juvenile.

## Onboarding

Never start a new user at Level 1, 0 XP, no accomplishments. Most people
have already accomplished meaningful things before installing the app.

Onboarding should allow users to rapidly create a retrospective life
profile. Present common achievements and allow users to quickly choose:
Done / Want to do / Not interested.

Within several minutes the user should have existing achievements, initial
XP, an overall level, category levels, and several possible future goals.

The user should quickly feel: "This looks like my life."

## Discovery

Users should be able to browse achievements similarly to discovering
content. Possible discovery surfaces: recommended, categories, trending,
rare achievements, nearby difficulty, quest chains, friends' achievements,
random side quests.

Users should not have to invent every goal themselves.

## User-Created Achievements

Users may create their own achievements. The app should help them define:
name, category, description, completion criteria, target, optional
milestones, optional deadline.

The experience should remain fast. Avoid turning goal creation into a form
with twenty required fields.

## Social Philosophy

Social functionality should be profile-first rather than feed-first. We do
not want to recreate Instagram.

Profiles may show: overall level, category levels, lifetime XP, trophy
case, selected stats, current quests, completed achievements, rare
achievements.

Users should control what is public.

## Trophy Case

Users may select a small number of achievements that best represent their
life. These do not need to be the achievements worth the most XP. A trophy
case should gradually become a miniature autobiography.

## Leaderboards

Leaderboards should emphasize relevant comparison. Priority:

1. Friends
2. Categories
3. Seasonal performance
4. Optional broader rankings

Avoid making lifetime global XP the dominant competition because early
adopters or extreme users could become permanently unreachable.

Lifetime progression does not reset. Competitive seasonal scores may
reset.

## Seasons

The product may periodically summarize recent progression, e.g. "Summer
2027: 4,750 XP earned, 13 achievements completed, Adventure was your
strongest category, largest achievement: Mount Rainier, 3 new personal
records."

Seasonal statistics may reset for leaderboard purposes. Lifetime
achievements and XP never reset. Do not build manipulative battle passes
around seasons.

## Charts and Analytics

Analytics should be powerful but optional: XP over time, achievements
completed over time, category distribution, completion rate, personal
record history, lifetime progression, achievement rarity, quest
completion, seasonal comparisons, friend comparison, achievement calendar,
category level changes.

A casual user should never need to look at these. A power user should be
able to spend significant time exploring them.

## AI Philosophy

AI is optional. The core application must be excellent without AI.

Potential premium AI functionality: recommend future achievements, convert
vague ambitions into measurable goals, generate quest chains, analyze
neglected life categories, generate personalized challenges, conduct
annual or seasonal life reviews, suggest realistic next milestones.

AI should provide specific usefulness. Avoid generic motivational-chatbot
behavior.

## Monetization Philosophy

The free product must genuinely work. Do not intentionally cripple basic
goal tracking.

Never charge for: basic achievements, adding normal goals, completing
achievements, standard XP, essential progress history.

Potential premium areas: advanced AI functionality, advanced analytics,
deep customization, specialized integrations, enhanced historical
analysis, premium profile customization, convenience features with real
incremental cost.

Monetization should generate sustainable profit without creating
resentment.

No dark patterns. No fake urgency. No XP purchases. No pay-to-win
progression. No manipulative streak-loss systems.

## Design Philosophy

The application should feel: comfortable, polished, slightly premium,
satisfying, calm, modern, playful without looking childish,
information-rich when requested, uncluttered by default.

Think sophisticated consumer software, not corporate project management
software.

Use animation and haptics strategically. Achievement celebrations deserve
disproportionate design attention.

## Product Test

Before adding any significant feature, ask:

1. Does this help users accomplish or appreciate things in real life?
2. Does it reduce or increase friction?
3. Is the feature useful or merely engagement bait?
4. Does this belong on the simple surface or in the advanced layer?
5. Would a casual user understand the app without knowing this exists?
6. Does this make the product feel more like a life scoreboard or more
   like another productivity app?
7. Does this encourage healthy real-world behavior?
8. Are we rewarding accomplishment or merely app usage?

If a feature contradicts the product constitution, challenge it before
implementation.

## Development Philosophy

Prefer simple, maintainable architecture over premature sophistication.

Do not build infrastructure for millions of users before we have dozens.

Do not create features merely because they may someday be useful.

The founder is the Product Owner.

Agents should:

- explain meaningful product tradeoffs in plain English
- avoid forcing the founder to understand unnecessary implementation
  details
- make sensible technical decisions independently when the product
  implication is minor
- ask for founder input when a decision materially changes user
  experience, monetization, privacy, or product direction

Do not silently reinterpret product philosophy. When uncertain, return to
this document.
