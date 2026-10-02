# Kingjump (prototype)

Checkers roguelike: jump enemy pieces, chain multi-jumps for big scores (chips x mult), beat the round's score target, buy relics in the shop.

## Run it
1. Install Godot 4.3+ (free): https://godotengine.org/download
2. Open Godot, click Import, pick this folder's `project.godot`, then press Play (F5).

Tap a white piece, then tap a green dot to move. Jumping a red piece scores; if another jump is available the chain continues. Gold squares give +30 chips, red squares +2 mult when you land on them by jumping.

After your move the **bot** plays one real checkers move: captures are mandatory, it finishes multi-jumps, crowns on your back row, and avoids leaving pieces hanging. It blunders less each round. Its last move is tinted red.

**Cards:** you hold up to 3 booster cards and tap one to use it during a round (Double Down, Overtime, Reinforcements, Coronation, Cannonball, Gold Rain). You draw a free card each round and can buy more.

**Shop:** relics (passive), cards, and **training** (stacking pawn or king upgrades: +chips, +mult or +$ per jump; each repeat costs $2 more).

## Tests
`godot --headless --path . -s tests/run_tests.gd`

## Layout
- `scripts/board.gd`: board and move rules
- `scripts/game.gd`: rounds, scoring, enemy turns, shop
- `scripts/relics.gd`: the 10 upgrade relics
- `scripts/content.gd`: booster cards and pawn/king training
- `scripts/main.gd`: drawing and input (placeholder art)
