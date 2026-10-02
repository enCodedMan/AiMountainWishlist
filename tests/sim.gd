extends SceneTree
## Balance simulator: a greedy "decent player" bot plays full runs headless.
## godot --headless --path . -s tests/sim.gd   (env SIM_RUNS, SIM_ARMY optional)

const Game = preload("res://scripts/game.gd")
const Board = preload("res://scripts/board.gd")
const Cards = preload("res://scripts/cards.gd")

var rng := RandomNumberGenerator.new()


func _init() -> void:
	var runs := int(OS.get_environment("SIM_RUNS")) if OS.get_environment("SIM_RUNS") != "" else 200
	var armies: Array = [OS.get_environment("SIM_ARMY")] if OS.get_environment("SIM_ARMY") != "" else Game.ARMIES.keys()
	rng.seed = 7
	for army in armies:
		var antes := {}
		var wins := 0
		var lost_on_boss := 0
		for r in runs:
			var g := Game.new()
			g.army = army
			g.new_run(1000 + r)
			play_run(g)
			antes[g.ante()] = antes.get(g.ante(), 0) + 1
			if g.state == "won":
				wins += 1
			elif g.stage() == 2:
				lost_on_boss += 1
		var keys := antes.keys()
		keys.sort()
		var dist := []
		for k in keys:
			dist.append("%d:%d" % [k, antes[k]])
		print("%-9s win %5.1f%%  lost-on-boss %4.1f%%  ante reached %s" % [army, 100.0 * wins / runs, 100.0 * lost_on_boss / runs, " ".join(dist)])
	quit()


func play_run(g: Game) -> void:
	for step in 2000:
		match g.state:
			"won", "lost":
				return
			"shop":
				shop(g)
				g.next_round()
			"play":
				play_turn(g)


## Player chains from every piece (reuses the bot's chain search, which is colour-agnostic).
func player_moves(g: Game) -> Array:
	var b: Board = g.board
	var caps: Array = []
	var steps: Array = []
	for p in b.positions_of(Board.is_player):
		g._collect_chains(b, p, p, [], [], caps)
		for to in b.steps_from(p):
			steps.append({"from": p, "path": [to], "captured": []})
	return caps if not caps.is_empty() else steps


func value(g: Game, m: Dictionary) -> float:
	var v := 0.0
	v += 10.0 * m.captured.size() * m.captured.size()
	for c in m.path:
		var t: int = g.board.get_tile(c)
		if t == Board.Tile.GOLD:
			v += 6.0
		elif t == Board.Tile.RED:
			v += 8.0
	var to: Vector2i = m.path.back()
	if g.board.get_cell(m.from) == Board.PAWN and to.y == 0:
		v += 8.0
	# Don't leave the piece hanging.
	var after: Board = g.board.copy()
	var piece := after.get_cell(m.from)
	after.set_cell(m.from, Board.EMPTY)
	for c in m.captured:
		after.set_cell(c, Board.EMPTY)
	after.set_cell(to, piece)
	for q in after.positions_of(Board.is_foe):
		for land in after.jumps_from(q):
			if (q + land) / 2 == to:
				v -= 7.0
	# Quiet moves: drift toward the enemy so jumps appear next turn.
	if m.captured.is_empty():
		v += (m.from.y - to.y) * 1.0
	return v + rng.randf()


func play_turn(g: Game) -> void:
	var moves := player_moves(g)
	if moves.is_empty():
		g.state = "lost"
		return
	var best: Dictionary = moves[0]
	var bv := -INF
	for m in moves:
		var v := value(g, m)
		if v > bv:
			bv = v
			best = m
	g.tap(best.from)
	var at: Vector2i = best.from
	for to in best.path:
		if g.state != "play":
			return
		if not g.tap(to):
			return
		at = to


## Shop policy: buy the best-rated affordable cards, then training.
func card_score(id: String) -> float:
	var info: Dictionary = Cards.ALL[id]
	return info.rarity * 3.0 + (2.0 if "x" in info.desc and "mult" in info.desc else 0.0) + rng.randf()


func shop(g: Game) -> void:
	for pass_i in 3:
		var best := -1
		var bs := -INF
		for i in g.shop.size():
			if not g.can_buy(i):
				continue
			var it: Dictionary = g.shop[i]
			var s := card_score(it.id) + 2.0 if it.kind == "card" else 1.0 + rng.randf()
			if s > bs:
				bs = s
				best = i
		if best < 0:
			return
		g.buy(best)
