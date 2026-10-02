extends RefCounted
## Persistent player profile: settings, lifetime stats and card unlocks.

const PATH := "user://profile.json"

## Cards available from the very first run. The rest unlock through play.
const STARTER := [
	"heavy", "opener", "pawnpride", "royalblood", "bounty", "golddigger",
	"longjump", "piggy", "patient", "momentum", "redcarpet", "reinforce",
	"steady", "edge", "deepstrike", "goldsmith", "firstblood", "pairs",
	"fortress", "underdog", "court", "greed", "zigzag", "rhythm",
]

const UNLOCK_HINTS := {
	"hattrick": "Make a 3-jump chain",
	"snowball": "Reach ante 2",
	"executioner": "Capture an enemy king",
	"martyr": "Lose 10 pieces in total",
	"blast": "Crown 3 pawns in total",
	"kingmaker": "Crown 8 pawns in total",
	"doubleagent": "Score 500 in a single move",
	"laststand": "Clear a round with only 1 piece left",
	"cleansweep": "Capture 100 enemies in total",
	"echo": "Reach ante 4",
	"tyrant": "Have 3 kings at once",
	"phoenix": "Lose 30 pieces in total",
	"copycat": "Win a run",
	"overtime": "Reach ante 6",
	"midas": "Score 2000 in a single move",
	"collector": "Capture 250 enemies in total",
}

const ARMY_HINTS := {
	"merchant": "Reach ante 3",
	"crowned": "Crown 5 pawns in total",
	"militia": "Lose 20 pieces in total",
}

var data := {}
var path := PATH


func _init() -> void:
	data = _defaults()


func _defaults() -> Dictionary:
	return {
		"unlocked": STARTER.duplicate(), "runs": 0, "wins": 0, "best_ante": 0, "best_move": 0,
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
		"hattrick":
			return rs.max_chain >= 3
		"snowball":
			return game.ante() >= 2
		"executioner":
			return rs.king_captures >= 1
		"martyr":
			return data.lost + rs.lost >= 10
		"blast":
			return data.crowns + rs.crowns >= 3
		"kingmaker":
			return data.crowns + rs.crowns >= 8
		"doubleagent":
			return rs.best_move >= 500
		"laststand":
			return rs.lone_clear
		"cleansweep":
			return data.captures + rs.captures >= 100
		"echo":
			return game.ante() >= 4
		"tyrant":
			return game.board.positions_of(func(v): return v == 2).size() >= 3
		"phoenix":
			return data.lost + rs.lost >= 30
		"copycat":
			return data.wins >= 1 or game.state == "won"
		"overtime":
			return game.ante() >= 6
		"midas":
			return rs.best_move >= 2000
		"collector":
			return data.captures + rs.captures >= 250
		"merchant":
			return game.ante() >= 3
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
	data.best_move = maxi(int(data.best_move), int(rs.best_move))
	data.captures += rs.captures
	data.crowns += rs.crowns
	data.lost += rs.lost
	save_profile()
