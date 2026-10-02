extends RefCounted
## Booster cards (held consumables) and piece training (stacking pawn/king upgrades).

const HAND_SIZE := 3

const CARDS := {
	"double": {"name": "Double Down", "desc": "Your next chain gets x2 mult", "cost": 3},
	"overtime": {"name": "Overtime", "desc": "+1 turn this round", "cost": 3},
	"reinforce": {"name": "Reinforcements", "desc": "Place a new pawn on your back row", "cost": 3},
	"coronation": {"name": "Coronation", "desc": "Crown the selected pawn", "cost": 4},
	"cannonball": {"name": "Cannonball", "desc": "Destroy the most advanced enemy piece", "cost": 3},
	"goldrain": {"name": "Gold Rain", "desc": "2 empty squares turn gold", "cost": 3},
}

## piece: which piece the bonus applies to; stat: chips | mult | coins (per jump).
const TRAINING := {
	"pawn_chips": {"name": "Pawn Drills", "desc": "Pawn jumps +5 chips", "piece": "pawn", "stat": "chips", "amount": 5, "cost": 3},
	"pawn_mult": {"name": "Pawn Fervor", "desc": "Pawn jumps +1 mult", "piece": "pawn", "stat": "mult", "amount": 1, "cost": 4},
	"pawn_coins": {"name": "Pawn Bounty", "desc": "Pawn jumps earn +$1", "piece": "pawn", "stat": "coins", "amount": 1, "cost": 4},
	"king_chips": {"name": "Royal Guard", "desc": "King jumps +10 chips", "piece": "king", "stat": "chips", "amount": 10, "cost": 3},
	"king_mult": {"name": "Royal Decree", "desc": "King jumps +2 mult", "piece": "king", "stat": "mult", "amount": 2, "cost": 5},
	"king_coins": {"name": "Royal Tax", "desc": "King jumps earn +$2", "piece": "king", "stat": "coins", "amount": 2, "cost": 5},
}

## Training gets pricier each time you buy the same one.
const TRAINING_COST_STEP := 2
