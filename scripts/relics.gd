extends RefCounted
## Upgrade ("relic") catalogue. Effects are applied in game.gd by id.

const ALL := {
	"heavy": {"name": "Heavy Crown", "desc": "+5 chips per jump", "cost": 4},
	"third": {"name": "Hat Trick", "desc": "Every 3rd jump in a chain doubles mult", "cost": 6},
	"crown": {"name": "Royal Leap", "desc": "Jumps by a king give +15 chips", "cost": 5},
	"opener": {"name": "Opening Gambit", "desc": "First jump of each chain gives +2 mult", "cost": 4},
	"goldrush": {"name": "Gold Rush", "desc": "Gold tiles give double chips", "cost": 4},
	"boom": {"name": "Coronation Blast", "desc": "Promotion captures adjacent foes", "cost": 6},
	"momentum": {"name": "Momentum", "desc": "+1 mult for each 2+ chain made this round", "cost": 5},
	"recruit": {"name": "Recruit", "desc": "Start each round with +1 pawn", "cost": 5},
	"patience": {"name": "Patience", "desc": "+1 turn every round", "cost": 5},
	"interest": {"name": "Piggy Bank", "desc": "Earn $1 per $5 held after each round (max $5)", "cost": 4},
}
