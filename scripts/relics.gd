extends RefCounted
## Relics: passive upgrades that bend the rules of checkers. Hold up to SLOTS.
## Effects are applied in game.gd by id.

const SLOTS := 5
const SELL_RATIO := 0.5

## rarity: 0 common, 1 uncommon, 2 rare. tag says when it matters.
const ALL := {
	"backstab": {"name": "Backstab", "desc": "Your pawns can capture backwards", "rarity": 0, "cost": 5, "tag": "RULE"},
	"sprint": {"name": "Sprint", "desc": "Your pawns can step 2 squares forward", "rarity": 0, "cost": 4, "tag": "RULE"},
	"momentum": {"name": "Momentum", "desc": "Capture 2+ pieces in one move: move again", "rarity": 1, "cost": 6, "tag": "TEMPO"},
	"phoenix": {"name": "Phoenix", "desc": "The first piece you lose each round returns on your back row", "rarity": 0, "cost": 5, "tag": "DEFENSE"},
	"bomb": {"name": "Powder Keg", "desc": "When the bot captures your piece, it explodes and destroys adjacent enemies", "rarity": 0, "cost": 5, "tag": "DEFENSE"},
	"blast": {"name": "Coronation Blast", "desc": "When you crown, destroy adjacent enemies", "rarity": 0, "cost": 4, "tag": "CROWN"},
	"bounty": {"name": "Bounty", "desc": "+$1 per capture", "rarity": 0, "cost": 4, "tag": "GOLD"},
	"hunter": {"name": "Hunter", "desc": "Capture 2+ pieces in one move: +$2", "rarity": 0, "cost": 4, "tag": "GOLD"},
	"greed": {"name": "Greed", "desc": "Win a round: +$1 per turn left", "rarity": 0, "cost": 4, "tag": "GOLD"},
	"piggy": {"name": "Piggy Bank", "desc": "Win a round: +$1 per $5 you hold (max $5)", "rarity": 0, "cost": 4, "tag": "GOLD"},
	"recruiter": {"name": "Recruiter", "desc": "Round start: a new pawn joins your army if there's room", "rarity": 1, "cost": 6, "tag": "ARMY"},
	"scout": {"name": "Scout", "desc": "Round start: the enemy's most advanced piece is removed", "rarity": 1, "cost": 6, "tag": "START"},
	"flying": {"name": "Flying Kings", "desc": "Your kings move and capture any distance diagonally", "rarity": 2, "cost": 8, "tag": "RULE"},
	"early": {"name": "Early Crown", "desc": "Your pawns crown one row early", "rarity": 1, "cost": 6, "tag": "CROWN"},
	"rush": {"name": "Coronation Rush", "desc": "When you crown, move again", "rarity": 1, "cost": 6, "tag": "TEMPO"},
	"iron": {"name": "Iron Kings", "desc": "Your kings can't be captured", "rarity": 2, "cost": 8, "tag": "DEFENSE"},
	"fortress": {"name": "Fortress", "desc": "Your pieces on your back row can't be captured", "rarity": 1, "cost": 5, "tag": "DEFENSE"},
	"lightning": {"name": "Chain Lightning", "desc": "Capture 3+ pieces in one move: destroy another enemy", "rarity": 1, "cost": 6, "tag": "CHAIN"},
	"executioner": {"name": "Executioner", "desc": "Capture an enemy king: +$3 and destroy an enemy pawn", "rarity": 1, "cost": 5, "tag": "CHAIN"},
	"undertow": {"name": "Undertow", "desc": "Enemies that break through cost no turns and pay you $2", "rarity": 2, "cost": 7, "tag": "RULE"},
}
