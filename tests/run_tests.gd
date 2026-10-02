extends SceneTree
## Headless logic tests: godot --headless --path . -s tests/run_tests.gd

const Game = preload("res://scripts/game.gd")
const Board = preload("res://scripts/board.gd")
const Profile = preload("res://scripts/profile.gd")
const Relics = preload("res://scripts/relics.gd")
const Formations = preload("res://scripts/formations.gd")

var failures := 0
var ran_all := false


func check(cond: bool, label: String) -> void:
	if cond:
		print("  ok   ", label)
	else:
		failures += 1
		print("  FAIL ", label)


## A game in play with a hand-built board and a bot that never blunders.
func blank_game(cells := {}) -> Game:
	var g := Game.new()
	g.new_run(1)
	g.round_num = 2  # a Big round: no blunders
	g.board = Board.new()
	for p in cells:
		g.board.set_cell(p, cells[p])
	g.turns_left = 12
	g.max_turns = 12
	g.take_events()
	return g


func _init() -> void:
	test_capture_is_mandatory()
	test_chain_jump()
	test_pawn_crowns()
	test_soft_lock_no_moves_loses_round()
	test_bot_no_moves_wins_round()
	test_out_of_turns()
	test_win_round_keeps_survivors()
	test_formations()
	test_relic_rules()
	test_relic_triggers()
	test_bot()
	test_shop()
	test_profile_unlocks()
	test_random_runs_never_stall()
	ran_all = true
	print("FAILURES ", failures)
	quit(1 if failures > 0 or not ran_all else 0)


func test_capture_is_mandatory() -> void:
	print("capture is mandatory")
	var g := blank_game({Vector2i(1, 4): Board.PAWN, Vector2i(5, 4): Board.PAWN, Vector2i(2, 3): Board.FOE, Vector2i(5, 0): Board.FOE})
	check(g.must_capture(), "a capture is available")
	check(g.movable_pieces() == [Vector2i(1, 4)], "only the capturing piece may move")
	g.tap(Vector2i(5, 4))
	check(g.selected != Vector2i(5, 4), "the other piece can't be selected")


func test_chain_jump() -> void:
	print("chain jump")
	var g := blank_game({Vector2i(0, 5): Board.PAWN, Vector2i(1, 4): Board.FOE, Vector2i(3, 2): Board.FOE, Vector2i(5, 0): Board.FOE})
	g.tap(Vector2i(0, 5))
	g.tap(Vector2i(2, 3))
	check(g.in_chain, "after the first jump the chain continues")
	g.tap(Vector2i(4, 1))
	check(g.run_stats.max_chain == 2, "two pieces captured in one move")


func test_pawn_crowns() -> void:
	print("crowning")
	var g := blank_game({Vector2i(1, 2): Board.PAWN, Vector2i(2, 1): Board.FOE, Vector2i(5, 4): Board.FOE})
	g.tap(Vector2i(1, 2))
	g.tap(Vector2i(3, 0))
	check(g.run_stats.crowns == 1, "a pawn reaching the far row crowns")


func test_soft_lock_no_moves_loses_round() -> void:
	print("soft lock: player with no moves")
	# The only pawn is blocked: forward square occupied, jump landing occupied.
	var g := blank_game({Vector2i(0, 5): Board.PAWN, Vector2i(1, 4): Board.FOE, Vector2i(2, 3): Board.FOE, Vector2i(5, 0): Board.FOE})
	g.hearts = 3
	check(g._check_round_over(), "a blocked player ends the round")
	check(g.state == "shop" and g.hearts == 2, "the round is lost, costing a life")
	check(g.army == [Board.PAWN], "the blocked pawn survives into the shop")


func test_bot_no_moves_wins_round() -> void:
	print("bot with no moves")
	var g := blank_game({Vector2i(1, 4): Board.PAWN, Vector2i(0, 5): Board.FOE})
	var money: int = g.money
	g._check_round_over()
	check(g.state == "shop" and g.last_result == "won", "a stuck bot loses the round")
	check(g.money > money, "won rounds pay")


func test_out_of_turns() -> void:
	print("turn limit")
	var g := blank_game({Vector2i(1, 4): Board.PAWN, Vector2i(5, 0): Board.FOE})
	g.turns_left = 1
	g.tap(Vector2i(1, 4))
	g.tap(Vector2i(0, 3))
	check(g.state == "shop" and g.last_result == "lost", "running out of turns loses the round")


func test_win_round_keeps_survivors() -> void:
	print("army persists")
	var g := blank_game({Vector2i(1, 4): Board.PAWN, Vector2i(3, 4): Board.KING, Vector2i(2, 3): Board.FOE})
	g.tap(Vector2i(1, 4))
	g.tap(Vector2i(3, 2))
	check(g.state == "shop", "capturing the last enemy wins")
	check(g.army.size() == 2 and g.army.has(Board.KING), "survivors carry over")
	var n := Formations.build(g.formation, g.ante()).size()
	g.next_round()
	check(g.state == "play" and g.board.count_side(1) == 2, "next round places the army")
	check(g.board.count_side(-1) == n, "the previewed formation is placed")


func test_formations() -> void:
	print("formations")
	var ok := true
	for stage in 3:
		for f in Formations.pool(stage):
			for ante in range(1, 8):
				var seen := {}
				for p in Formations.build(f, ante):
					var c := Vector2i(p[0], p[1])
					if not Board.is_dark(c) or c.y > 2 or seen.has(c):
						ok = false
					seen[c] = true
	check(ok, "every formation uses distinct dark squares in the enemy rows")
	check(Formations.build(Formations.SMALL[0], 3).size() == 5, "later antes add pieces")


func test_relic_rules() -> void:
	print("relic rules")
	var g := blank_game({Vector2i(2, 3): Board.PAWN, Vector2i(3, 4): Board.FOE, Vector2i(5, 0): Board.FOE})
	check(not g.must_capture(), "pawns can't capture backwards by default")
	g.relics = ["backstab"]
	check(g.must_capture(), "Backstab allows backward captures")
	g = blank_game({Vector2i(1, 4): Board.PAWN, Vector2i(5, 0): Board.FOE})
	g.relics = ["sprint"]
	check(g.legal_targets(Vector2i(1, 4)).has(Vector2i(3, 2)), "Sprint steps two squares")
	g = blank_game({Vector2i(1, 4): Board.KING, Vector2i(4, 1): Board.FOE})
	g.relics = ["flying"]
	check(g.legal_targets(Vector2i(1, 4)).has(Vector2i(5, 0)), "Flying Kings capture at range")
	g = blank_game({Vector2i(3, 2): Board.PAWN, Vector2i(5, 0): Board.FOE})
	g.relics = ["early"]
	g.tap(Vector2i(3, 2))
	g.tap(Vector2i(2, 1))
	check(g.run_stats.crowns == 1, "Early Crown crowns on row 1")
	g = blank_game({Vector2i(3, 4): Board.KING, Vector2i(2, 3): Board.FOE, Vector2i(5, 0): Board.FOE})
	g.relics = ["iron"]
	check(g.board.legal_moves(-1, g.foe_rules(), g.player_rules()).all(func(m): return m.caps.is_empty()), "Iron Kings can't be captured")
	g.round_num = 3
	g.boss = "silence"
	check(not g.has("iron"), "Silence disables the leftmost relic")
	g = blank_game({Vector2i(5, 4): Board.PAWN, Vector2i(1, 4): Board.FOE})
	g._bot_turn()
	check(g.board.count_side(-1) == 0 and g.turns_left == 12 - Game.BREAKTHROUGH_COST, "an enemy pawn breaking through costs turns")
	g = blank_game({Vector2i(5, 4): Board.PAWN, Vector2i(1, 4): Board.FOE})
	g.relics = ["undertow"]
	var cash: int = g.money
	g._bot_turn()
	check(g.turns_left == 12 and g.money == cash + 2, "Undertow turns breakthroughs into gold")


func test_relic_triggers() -> void:
	print("relic triggers")
	var g := blank_game({Vector2i(0, 5): Board.PAWN, Vector2i(1, 4): Board.FOE, Vector2i(3, 2): Board.FOE, Vector2i(5, 0): Board.FOE, Vector2i(1, 0): Board.FOE})
	g.relics = ["bounty", "hunter", "momentum"]
	var money: int = g.money
	g.tap(Vector2i(0, 5))
	g.tap(Vector2i(2, 3))
	g.tap(Vector2i(4, 1))
	check(g.money == money + 4, "Bounty +$2 and Hunter +$2")
	check(g.message == "Move again!" and g.turns_left == 11, "Momentum grants another move")
	g = blank_game({Vector2i(2, 3): Board.PAWN, Vector2i(4, 5): Board.PAWN, Vector2i(1, 2): Board.FOE, Vector2i(5, 0): Board.FOE})
	g.relics = ["bomb"]
	g._bot_turn()
	check(g.board.get_cell(Vector2i(3, 4)) == Board.EMPTY and g.board.count_side(-1) == 1, "Powder Keg destroys the capturer")
	g = blank_game({Vector2i(2, 3): Board.PAWN, Vector2i(1, 2): Board.FOE, Vector2i(5, 0): Board.FOE})
	g.relics = ["phoenix"]
	g._bot_turn()
	check(g.board.count_side(1) == 1 and g.phoenix_used, "Phoenix revives the lost piece")
	g = blank_game({Vector2i(1, 2): Board.PAWN, Vector2i(2, 1): Board.FOE, Vector2i(4, 1): Board.FOE, Vector2i(0, 1): Board.FOE})
	g.relics = ["blast"]
	g.tap(Vector2i(1, 2))
	g.tap(Vector2i(3, 0))
	check(g.board.count_side(-1) == 1 and g.run_stats.crowns == 1, "Coronation Blast clears neighbours on crowning")
	g = Game.new()
	g.new_run(3)
	g.relics = ["scout"]
	g.state = "shop"
	var n := Formations.build(g.formation, g.ante()).size()
	g.next_round()
	check(g.board.count_side(-1) == n - 1, "Scout removes one enemy at round start")


func test_bot() -> void:
	print("bot")
	var g := blank_game({Vector2i(2, 3): Board.PAWN, Vector2i(1, 2): Board.FOE, Vector2i(5, 0): Board.FOE, Vector2i(5, 4): Board.PAWN})
	g._bot_turn()
	check(g.board.count_side(1) == 1, "the bot must capture")
	var safe := 0
	for i in 20:
		var h := blank_game({Vector2i(3, 4): Board.PAWN, Vector2i(1, 2): Board.FOE, Vector2i(5, 0): Board.FOE})
		h.rng.seed = i
		h._bot_turn()
		if h.board.get_cell(Vector2i(2, 3)) == Board.EMPTY:
			safe += 1
	check(safe == 20, "the bot doesn't hang a piece (%d/20)" % safe)
	var a := Game.new()
	a.new_run(1)
	check(a.bot_depth() == 1 and a.bot_blunder_chance() > 0.0, "the first round is gentle")
	a.round_num = 9
	check(a.bot_depth() >= 3, "bosses later think deeper")


func test_shop() -> void:
	print("shop")
	var g := blank_game({Vector2i(1, 4): Board.PAWN, Vector2i(2, 3): Board.FOE})
	g.tap(Vector2i(1, 4))
	g.tap(Vector2i(3, 2))
	check(g.state == "shop" and g.shop.size() == Game.SHOP_RELICS, "the shop offers relics")
	g.money = 30
	var id: String = g.shop[0]
	check(g.buy(0) and g.relics == [id] and not g.shop.has(id), "buy a relic")
	check(g.recruit() and g.army.size() == 2, "recruit a pawn")
	check(g.crown_pawn() and g.army.has(Board.KING), "crown a pawn")
	var before: int = g.money
	var value := g.sell_value(0)
	check(g.sell(0) and g.money == before + value and g.relics.is_empty(), "sell a relic")
	g.army = []
	g.next_round()
	check(g.state == "lost", "an empty army ends the run")


func test_profile_unlocks() -> void:
	print("profile")
	var pr := Profile.new()
	pr.path = "user://test_profile.json"
	var g := Game.new()
	g.new_run(5)
	g.round_num = 4  # ante 2
	g.run_stats.king_captures = 1
	var fresh := pr.check_unlocks(g)
	check(fresh.has("early") and fresh.has("executioner") and fresh.has("army:merchant"), "milestones unlock relics and armies")
	pr.end_run(g, false)
	check(pr.data.runs == 1 and pr.data.best_ante == 2, "the run is recorded")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(pr.path))


## Random legal play must never reach a state where the round goes on but the player can't act.
func test_random_runs_never_stall() -> void:
	print("random runs")
	var stalls := 0
	var finished := 0
	for seed_i in 40:
		var g := Game.new()
		g.army_id = Game.ARMIES.keys()[seed_i % Game.ARMIES.size()]
		g.new_run(100 + seed_i)
		var r := RandomNumberGenerator.new()
		r.seed = seed_i
		for step in 3000:
			if g.state == "won" or g.state == "lost":
				finished += 1
				break
			if g.state == "shop":
				for k in 3:
					if g.can_buy(0):
						g.buy(0)
				if g.can_recruit():
					g.recruit()
				g.next_round()
				continue
			var mv := g.movable_pieces()
			if mv.is_empty():
				stalls += 1
				break
			if not g.in_chain:
				g.tap(mv[r.randi_range(0, mv.size() - 1)])
			var t := g.legal_targets(g.selected)
			if t.is_empty():
				stalls += 1
				break
			g.tap(t[r.randi_range(0, t.size() - 1)])
	check(stalls == 0, "no stuck states in 40 random runs (%d stalls)" % stalls)
	check(finished == 40, "every random run ends (%d/40)" % finished)
