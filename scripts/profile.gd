extends RefCounted
## Persistent player profile: settings, lifetime stats and relic unlocks.

const PATH := "user://profile.json"

## Relics available from the very first run. The rest unlock through play.
const STARTER := [
	"backstab", "sprint", "phoenix", "bomb", "blast", "bounty",
	"hunter", "greed", "piggy", "recruiter", "scout", "momentum",
]

const UNLOCK_HINTS := {
	"early": "Reach ante 2",
	"lightning": "Capture 3 pieces in one move",
	"executioner": "Capture an enemy king",
	"rush": "Crown 3 pawns in total",
	"fortress": "Lose 10 pieces in total",
	"undertow": "Reach ante 3",
	"flying": "Crown 8 pawns in total",
	"iron": "Beat 2 bosses in total",
}

const ARMY_HINTS := {
	"merchant": "Reach ante 2",
	"crowned": "Crown 5 pawns in total",
	"militia": "Lose 20 pieces in total",
}

var data := {}
var path := PATH


func _init() -> void:
	data = _defaults()


func _defaults() -> Dictionary:
	return {
		"unlocked": STARTER.duplicate(), "runs": 0, "wins": 0, "best_ante": 0, "bosses": 0,
		"captures": 0, "crowns": 0, "lost": 0, "sfx": true, "shake": true,
		"armies": ["classic"], "army": "classic",
	}


func load_profile() -> void:
	data = _defaults()
	if not FileAccess.file_exists(path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		for k in parsed:
			data[k] = parsed[k]
	var Relics = load("res://scripts/relics.gd")
	data.unlocked = data.unlocked.filter(func(id): return Relics.ALL.has(id))
	for id in STARTER:
		if not data.unlocked.has(id):
			data.unlocked.append(id)


func save_profile() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func is_unlocked(id: String) -> bool:
	return data.unlocked.has(id)


func _met(id: String, game) -> bool:
	var rs: Dictionary = game.run_stats
	match id:
		"early", "merchant":
			return game.ante() >= 2
		"lightning":
			return rs.max_chain >= 3
		"executioner":
			return rs.king_captures >= 1
		"rush":
			return data.crowns + rs.crowns >= 3
		"fortress":
			return data.lost + rs.lost >= 10
		"undertow":
			return game.ante() >= 3
		"flying":
			return data.crowns + rs.crowns >= 8
		"iron":
			return data.get("bosses", 0) + rs.bosses >= 2
		"crowned":
			return data.crowns + rs.crowns >= 5
		"militia":
			return data.lost + rs.lost >= 20
	return false


## Unlock anything newly earned. Returns the new ids so the UI can announce them.
func check_unlocks(game) -> Array:
	var fresh: Array = []
	for id in UNLOCK_HINTS:
		if not is_unlocked(id) and _met(id, game):
			data.unlocked.append(id)
			fresh.append(id)
	for id in ARMY_HINTS:
		if not data.armies.has(id) and _met(id, game):
			data.armies.append(id)
			fresh.append("army:" + id)
	if not fresh.is_empty():
		game.unlocked = data.unlocked.duplicate()
		save_profile()
	return fresh


## Fold a finished run into lifetime stats.
func end_run(game, won: bool) -> void:
	var rs: Dictionary = game.run_stats
	data.runs += 1
	if won:
		data.wins += 1
	data.best_ante = maxi(int(data.best_ante), game.ante())
	data.bosses = int(data.get("bosses", 0)) + rs.bosses
	data.captures += rs.captures
	data.crowns += rs.crowns
	data.lost += rs.lost
	save_profile()
