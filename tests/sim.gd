extends SceneTree
## Balance simulator: a "decent player" (2-ply lookahead) plays full runs headless.
## godot --headless --path . -s tests/sim.gd   (env SIM_RUNS, SIM_ARMY optional)

const Game = preload("res://scripts/game.gd")
const Board = preload("res://scripts/board.gd")
const Relics = preload("res://scripts/relics.gd")

var rng := RandomNumberGenerator.new()
var round_results := {}  # "ante-stage" -> [won, played]
var reasons := {}


func _init() -> void:
	var runs := int(OS.get_environment("SIM_RUNS")) if OS.get_environment("SIM_RUNS") != "" else 100
	var armies: Array = [OS.get_environment("SIM_ARMY")] if OS.get_environment("SIM_ARMY") != "" else Game.ARMIES.keys()
	rng.seed = 7
	for army in armies:
		var antes := {}
		var wins := 0
		for r in runs:
			var g := Game.new()
			g.army_id = army
			g.new_run(1000 + r)
			play_run(g)
			antes[g.ante()] = antes.get(g.ante(), 0) + 1
			if g.state == "won":
				wins += 1
		var keys := antes.keys()
		keys.sort()
		var dist := []
		for k in keys:
			dist.append("%d:%d" % [k, antes[k]])
		print("%-9s win %5.1f%%  ante reached %s" % [army, 100.0 * wins / runs, " ".join(dist)])
	var rk := round_results.keys()
	rk.sort()
	var line := []
	for k in rk:
		line.append("%s %d%%" % [k, 100 * round_results[k][0] / round_results[k][1]])
	print("round win rate: ", ", ".join(line))
	print("losses: ", reasons)
	quit()


func play_run(g: Game) -> void:
	for step in 5000:
		match g.state:
			"won", "lost":
				return
			"shop":
				shop(g)
				g.next_round()
			"play":
				var key := "%d%s" % [g.ante(), "sbB"[g.stage()]]
				var rn := g.round_num
				play_turn(g)
				if g.round_num != rn or g.state != "play":
					var rr: Array = round_results.get(key, [0, 0])
					rr[1] += 1
					if g.last_result == "won" or g.state == "won":
						rr[0] += 1
					else:
						var why: String = g.message.split(".")[0]
						reasons[why] = reasons.get(why, 0) + 1
					round_results[key] = rr


## Score a full move by the bot's best reply (from the player's side).
func value(g: Game, m: Dictionary) -> float:
	var pr := g.player_rules()
	var fr := g.foe_rules()
	var b: Board = g.board.copy()
	b.apply_move(m, pr)
	var v := -g._search(b, -1, 1, -INF, INF)
	# Push forward when nothing's happening, so the turn limit isn't wasted.
	v += (m.from.y - m.path.back().y) * 0.5
	return v + rng.randf() * 0.3


func play_turn(g: Game) -> void:
	var moves := g.board.legal_moves(1, g.player_rules(), g.foe_rules())
	if moves.is_empty():
		g._check_round_over()
		return
	var best: Dictionary = moves[0]
	var bv := -INF
	for m in moves:
		var v := value(g, m)
		if v > bv:
			bv = v
			best = m
	g.tap(best.from)
	for to in best.path:
		if g.state != "play" or not g.tap(to):
			return


func shop(g: Game) -> void:
	if g.army.size() < 4 and g.can_recruit():
		g.recruit()
	for pass_i in 2:
		var best := -1
		var bs := -INF
		for i in g.shop.size():
			if g.can_buy(i):
				var s: float = Relics.ALL[g.shop[i]].rarity + rng.randf()
				if s > bs:
					bs = s
					best = i
		if best >= 0:
			g.buy(best)
	if g.can_crown() and g.money >= Game.CROWN_COST + 2:
		g.crown_pawn()
	while g.can_recruit() and g.money >= Game.RECRUIT_COST + 3:
		g.recruit()
