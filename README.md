# Kingjump (prototype)

Checkers roguelike: every round is a real game of checkers against a bot. Capture every enemy piece before your turns run out, then spend your winnings on relics that bend the rules.

## Run it
1. Install Godot 4.3+ (free): https://godotengine.org/download
2. Open Godot, click Import, pick this folder's `project.godot`, then press Play (F5).

Tap a white piece, then tap a green dot to move. Captures are mandatory for both sides (glowing pieces must jump) and multi-jumps continue until no jump is left.

**Rounds:** 3 per ante (Small, Big, Boss), 5 antes to win, endless after. Enemies come in named, hand-placed formations (Wedge, Pincer, Phalanx...) that grow with the ante; the shop previews the next one. Bosses add a rule (Swift, Mirror, Ambush, Silence...). You get `8 + 3 per enemy` turns.

**The bot** looks ahead with minimax and thinks deeper each ante. Its pawns never crown: a pawn that reaches your back row breaks through and costs you a turn.

**Your army** carries over between rounds, and pieces the bot captures are gone for good. Recruit pawns ($3) or crown one ($5) in the shop.

**Lives:** 3. Losing a round (out of turns, or no legal moves) costs a life and you retry the same round. Losing your whole army ends the run.

**Relics (passive, 5 slots):** 26 relics in families that stack: RULE (Backstab, Sprint, Leapfrog, Flying Kings), CROWN (Early Crown 2 rows early, Coronation Blast, Heir, Kingmaker), CHAIN (Chain Lightning, Executioner, Turncoat), TEMPO (Momentum, Coronation Rush, Hourglass), DEFENSE (Phoenix, Powder Keg, Iron Kings, Fortress, Undertow), START (Scout, Quake) and GOLD. Order matters only for the Silence boss.

**No score.** Score was cut in v2: winning the checkers game is the goal, so every capture and every lost piece matters directly.

## Tests and balance
`godot --headless --path . -s tests/run_tests.gd` runs the logic tests, including random full runs that check the game never gets stuck.

`godot --headless --path . -s tests/sim.gd` plays full runs with a 2-ply "decent player" and prints win rate, ante reached and round win rates (set `SIM_RUNS` / `SIM_ARMY`).

## Layout
- `scripts/board.gd`: board, rules (mandatory capture, chains, rule-bending flags)
- `scripts/formations.gd`: hand-placed enemy formations
- `scripts/relics.gd`: the 20 relics
- `scripts/game.gd`: rounds, bot (minimax), relic triggers, shop
- `scripts/profile.gd`: save file, unlocks
- `scripts/main.gd`: drawing and input
