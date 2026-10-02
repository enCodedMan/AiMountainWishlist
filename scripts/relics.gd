extends RefCounted
## Relics: passive upgrades that bend the rules of checkers. Hold up to SLOTS.
## Effects are applied in game.gd by id.

const SLOTS := 5
const SELL_RATIO := 0.5

## rarity: 0 common, 1 uncommon, 2 rare. tag says when it matters.
const ALL := {
	# Rules: change how your pieces move.
	"backstab": {"name": "Backstab", "desc": "Your pawns can capture backwards", "rarity": 0, "cost": 5, "tag": "RULE"},
	"sprint": {"name": "Sprint", "desc": "Your pawns can step 2 squares forward", "rarity": 0, "cost": 4, "tag": "RULE"},
	"leapfrog": {"name": "Leapfrog", "desc": "Your pieces can hop over your own pieces", "rarity": 0, "cost": 4, "tag": "RULE"},
	"flying": {"name": "Flying Kings", "desc": "Your kings move and capture any distance diagonally", "rarity": 2, "cost": 8, "tag": "RULE"},
	# Tempo: more moves.
	"momentum": {"name": "Momentum", "desc": "Capture 2+ pieces in one move: move again", "rarity": 1, "cost": 6, "tag": "TEMPO"},
	"rush": {"name": "Coronation Rush", "desc": "When you crown, move again", "rarity": 1, "cost": 6, "tag": "TEMPO"},
	"hourglass": {"name": "Hourglass", "desc": "+5 turns every round", "rarity": 0, "cost": 4, "tag": "TEMPO"},
	# Crown: make and use kings.
	"early": {"name": "Early Crown", "desc": "Your pawns crown 2 rows early", "rarity": 1, "cost": 6, "tag": "CROWN"},
	"blast": {"name": "Coronation Blast", "desc": "When you crown, destroy every enemy around the new king", "rarity": 0, "cost": 4, "tag": "CROWN"},
	"heir": {"name": "Heir", "desc": "When you crown, a new pawn joins on your back row", "rarity": 1, "cost": 6, "tag": "CROWN"},
	"kingmaker": {"name": "Kingmaker", "desc": "Round start: your most advanced pawn is crowned", "rarity": 2, "cost": 8, "tag": "CROWN"},
	# Chain: reward multi-captures.
	"lightning": {"name": "Chain Lightning", "desc": "Capture 2+ pieces in one move: destroy a random enemy", "rarity": 1, "cost": 6, "tag": "CHAIN"},
	"executioner": {"name": "Executioner", "desc": "Capture an enemy king: +$3 and destroy 2 enemy pawns", "rarity": 1, "cost": 5, "tag": "CHAIN"},
	"turncoat": {"name": "Turncoat", "desc": "The first enemy you capture each round joins your army where it stood", "rarity": 2, "cost": 8, "tag": "CHAIN"},
	# Defense: survive the bot.
	"phoenix": {"name": "Phoenix", "desc": "The first 2 pieces you lose each round return on your back row", "rarity": 0, "cost": 5, "tag": "DEFENSE"},
	"bomb": {"name": "Powder Keg", "desc": "When the bot captures your piece, it explodes and destroys enemies around it", "rarity": 0, "cost": 5, "tag": "DEFENSE"},
	"iron": {"name": "Iron Kings", "desc": "Your kings can't be captured", "rarity": 2, "cost": 8, "tag": "DEFENSE"},
	"fortress": {"name": "Fortress", "desc": "Your pieces on your back two rows can't be captured", "rarity": 1, "cost": 5, "tag": "DEFENSE"},
	"undertow": {"name": "Undertow", "desc": "Enemies that break through cost no turns and pay you $2", "rarity": 1, "cost": 5, "tag": "DEFENSE"},
	# Start: shape the board before the first move.
	"scout": {"name": "Scout", "desc": "Round start: the 2 most advanced enemies are removed", "rarity": 1, "cost": 6, "tag": "START"},
	"quake": {"name": "Quake", "desc": "Round start: destroy every enemy on their front row", "rarity": 1, "cost": 6, "tag": "START"},
	"recruiter": {"name": "Recruiter", "desc": "Round start: a new pawn joins your army if there's room", "rarity": 0, "cost": 5, "tag": "ARMY"},
	# Gold.
	"bounty": {"name": "Bounty", "desc": "+$1 per capture", "rarity": 0, "cost": 4, "tag": "GOLD"},
	"hunter": {"name": "Hunter", "desc": "Capture 2+ pieces in one move: +$3", "rarity": 0, "cost": 4, "tag": "GOLD"},
	"greed": {"name": "Greed", "desc": "Win a round: +$1 per turn left", "rarity": 0, "cost": 4, "tag": "GOLD"},
	"piggy": {"name": "Piggy Bank", "desc": "Win a round: +$1 per $4 you hold (max $6)", "rarity": 0, "cost": 4, "tag": "GOLD"},
}
