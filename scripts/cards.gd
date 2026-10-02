extends RefCounted
## Passive cards. Each one triggers automatically on a game event, left to right.
## Effects live in game.gd (_card_effect), keyed by id.

const SLOTS := 5
const SELL_RATIO := 0.5

## rarity: 0 common, 1 uncommon, 2 rare. Shop odds favour commons.
const ALL := {
	"heavy": {"name": "Heavy Crown", "desc": "Every jump: +6 chips", "rarity": 0, "cost": 4},
	"opener": {"name": "Opening Gambit", "desc": "First jump of a chain: +3 mult", "rarity": 0, "cost": 4},
	"pawnpride": {"name": "Pawn Pride", "desc": "Pawn jumps: +8 chips", "rarity": 0, "cost": 4},
	"royalblood": {"name": "Royal Blood", "desc": "King jumps: +3 mult", "rarity": 0, "cost": 5},
	"bounty": {"name": "Bounty Hunter", "desc": "Every capture: +$1", "rarity": 0, "cost": 4},
	"golddigger": {"name": "Gold Digger", "desc": "Land on gold: +$2", "rarity": 0, "cost": 3},
	"longjump": {"name": "Long Jump", "desc": "Chains of 3+ jumps: +5 mult", "rarity": 0, "cost": 4},
	"patient": {"name": "Patient Hand", "desc": "Each quiet move (no jump) banks +4 mult for your next chain", "rarity": 1, "cost": 5},
	"hattrick": {"name": "Hat Trick", "desc": "Every 3rd jump in a chain: x2 mult", "rarity": 1, "cost": 6},
	"snowball": {"name": "Snowball", "desc": "Every jump: +N chips. N grows by 1 after each 2+ chain", "rarity": 1, "cost": 6},
	"martyr": {"name": "Martyr", "desc": "When the bot takes your piece, this gains +2 mult forever", "rarity": 1, "cost": 5},
	"momentum": {"name": "Momentum", "desc": "Chain end: +1 mult per 2+ chain this round", "rarity": 1, "cost": 5},
	"redcarpet": {"name": "Red Carpet", "desc": "Round start: add a red square. Red squares give double mult", "rarity": 1, "cost": 5},
	"reinforce": {"name": "Recruiter", "desc": "Round start: +1 pawn", "rarity": 1, "cost": 5},
	"blast": {"name": "Coronation Blast", "desc": "On crowning: destroy adjacent enemies, +20 chips each", "rarity": 1, "cost": 6},
	"kingmaker": {"name": "Kingmaker", "desc": "On crowning: +30 chips, +10 mult, +$3", "rarity": 1, "cost": 6},
	"piggy": {"name": "Piggy Bank", "desc": "Round end: +$1 per $5 you hold (max $5)", "rarity": 0, "cost": 4},
	"executioner": {"name": "Executioner", "desc": "Capturing a king: x2 mult", "rarity": 2, "cost": 7},
	"doubleagent": {"name": "Double Agent", "desc": "Chain end: x1.5 mult", "rarity": 2, "cost": 8},
	"laststand": {"name": "Last Stand", "desc": "Chain end with only 1 piece left: x3 mult", "rarity": 2, "cost": 6},
	"cleansweep": {"name": "Clean Sweep", "desc": "A chain that clears the board: x2 mult, +$5", "rarity": 2, "cost": 7},
	"echo": {"name": "Echo", "desc": "Retriggers the card to its left", "rarity": 2, "cost": 8},
}

## Stacking pawn/king upgrades, bought in the shop. stat: chips | mult | coins (per jump).
const TRAINING := {
	"pawn_chips": {"name": "Pawn Drills", "desc": "Pawn jumps +5 chips", "piece": "pawn", "stat": "chips", "amount": 5, "cost": 3},
	"pawn_mult": {"name": "Pawn Fervor", "desc": "Pawn jumps +1 mult", "piece": "pawn", "stat": "mult", "amount": 1, "cost": 4},
	"pawn_coins": {"name": "Pawn Bounty", "desc": "Pawn jumps earn +$1", "piece": "pawn", "stat": "coins", "amount": 1, "cost": 4},
	"king_chips": {"name": "Royal Guard", "desc": "King jumps +10 chips", "piece": "king", "stat": "chips", "amount": 10, "cost": 3},
	"king_mult": {"name": "Royal Decree", "desc": "King jumps +2 mult", "piece": "king", "stat": "mult", "amount": 2, "cost": 5},
	"king_coins": {"name": "Royal Tax", "desc": "King jumps earn +$2", "piece": "king", "stat": "coins", "amount": 2, "cost": 5},
}
const TRAINING_COST_STEP := 2
