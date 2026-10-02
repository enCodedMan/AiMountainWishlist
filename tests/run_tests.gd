extends SceneTree
## Headless logic tests: godot --headless --path . -s tests/run_tests.gd

const Game = preload("res://scripts/game.gd")
const Board = preload("res://scripts/board.gd")

var failures := 0


func check(cond: bool, label: String) -> void:
	if cond:
		print("  ok   ", label)
	else:
		failures += 1
		print("  FAIL ", label)


## A game with an empty, hand-built board.
func blank_game() -> Game:
	var g := Game.new()
	g.new_run(1)
	g.board = Board.new()
	g.target = 100000
	return g


func _init() -> void:
	test_double_jump_scores_chain()
	test_pawn_cannot_move_backwards()
	test_hat_trick_doubles_mult()
	test_round_win_opens_shop()
	test_shop_buy_and_next_round()
	test_out_of_turns_loses()
	test_random_runs_do_not_crash()
	print("FAILURES: ", failures)
	quit(1 if failures > 0 else 0)


func test_double_jump_scores_chain() -> void:
	print("double jump")
	var g := blank_game()
	g.board.set_cell(Vector2i(1, 5), Board.PAWN)
	g.board.set_cell(Vector2i(2, 4), Board.FOE)
	g.board.set_cell(Vector2i(4, 2), Board.FOE)
	g.board.set_cell(Vector2i(0, 0), Board.FOE)  # keeps the board from respawning
	g.tap(Vector2i(1, 5))
	check(g.legal_targets(Vector2i(1, 5)).has(Vector2i(3, 3)), "jump target offered")
	g.tap(Vector2i(3, 3))
	check(g.in_chain, "chain continues after first jump")
	check(g.legal_targets(Vector2i(3, 3)) == [Vector2i(5, 1)], "only the jump is offered mid-chain")
	g.tap(Vector2i(5, 1))
	check(not g.in_chain, "chain ended")
	check(g.score == 20 * 2, "2 jumps score 20 chips x 2 mult (got %d)" % g.score)
	check(g.board.get_cell(Vector2i(2, 4)) == Board.EMPTY and g.board.get_cell(Vector2i(4, 2)) == Board.EMPTY, "jumped foes removed")


func test_pawn_cannot_move_backwards() -> void:
	print("pawn direction")
	var g := blank_game()
	g.board.set_cell(Vector2i(2, 3), Board.PAWN)
	var t := g.legal_targets(Vector2i(2, 3))
	check(t.has(Vector2i(1, 2)) and t.has(Vector2i(3, 2)) and t.size() == 2, "pawn only steps forward")


func test_hat_trick_doubles_mult() -> void:
	print("hat trick relic")
	var g := blank_game()
	g.relics = ["third"]
	# King zigzag: (0,3) -> (2,1) -> (4,3) -> (2,5)
	g.board.set_cell(Vector2i(0, 3), Board.KING)
	g.board.set_cell(Vector2i(1, 2), Board.FOE)
	g.board.set_cell(Vector2i(3, 2), Board.FOE)
	g.board.set_cell(Vector2i(3, 4), Board.FOE)
	g.board.set_cell(Vector2i(5, 0), Board.FOE)  # keeps the board from respawning
	g.tap(Vector2i(0, 3))
	g.tap(Vector2i(2, 1))
	g.tap(Vector2i(4, 3))
	check(g.in_chain and g.chain_mult == 2, "2 jumps in, mult 2")
	g.tap(Vector2i(2, 5))
	check(g.score == 30 * 6, "3rd jump doubles mult: 30 chips x 6 (got %d)" % g.score)


func test_round_win_opens_shop() -> void:
	print("round win")
	var g := blank_game()
	g.target = 10
	g.money = 0
	g.board.set_cell(Vector2i(1, 5), Board.PAWN)
	g.board.set_cell(Vector2i(2, 4), Board.FOE)
	g.board.set_cell(Vector2i(0, 0), Board.FOE)
	g.tap(Vector2i(1, 5))
	g.tap(Vector2i(3, 3))
	check(g.state == "shop", "state is shop")
	check(g.money == 3 + g.turns_left, "earned $3 + turns left (got %d)" % g.money)
	check(g.shop_offer.size() == 3, "3 relics offered")


func test_shop_buy_and_next_round() -> void:
	print("shop")
	var g := blank_game()
	g.state = "shop"
	g.money = 100
	g.roll_shop()
	var id: String = g.shop_offer[0]
	check(g.buy(id), "buy succeeds")
	check(g.has(id) and not g.shop_offer.has(id), "relic owned and removed from shop")
	check(g.reroll(), "reroll succeeds")
	check(not g.shop_offer.has(id), "owned relic not re-offered")
	g.next_round()
	check(g.round_num == 2 and g.state == "play", "round 2 starts")
	check(g.target == 150, "round 2 target is 150 (got %d)" % g.target)


func test_out_of_turns_loses() -> void:
	print("lose")
	var g := blank_game()
	g.turns_left = 1
	g.board.set_cell(Vector2i(1, 5), Board.PAWN)
	g.board.set_cell(Vector2i(4, 0), Board.FOE)
	g.tap(Vector2i(1, 5))
	g.tap(Vector2i(0, 4))
	check(g.state == "lost", "run lost when turns run out")


## Random-play smoke test: many runs of random legal taps must never error or stall.
func test_random_runs_do_not_crash() -> void:
	print("random play")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var best := 0
	for run in 200:
		var g := Game.new()
		g.new_run(run)
		for step in 400:
			if g.state == "shop":
				if not g.shop_offer.is_empty():
					g.buy(g.shop_offer[0])
				g.next_round()
				continue
			if g.state == "lost":
				break
			var moves: Array = []
			for p in g.board.positions_of(Board.is_player):
				if g.in_chain and p != g.selected:
					continue
				for t in g.legal_targets(p):
					moves.append([p, t])
			if moves.is_empty():
				g.state = "lost"  # stuck: no legal move (counted as loss for the smoke test)
				break
			# Prefer jumps, like a player would.
			var jumps := moves.filter(func(m): return absi(m[1].x - m[0].x) == 2)
			var pick: Array = (jumps if not jumps.is_empty() else moves)[rng.randi_range(0, (jumps if not jumps.is_empty() else moves).size() - 1)]
			if not g.in_chain:
				g.tap(pick[0])
			g.tap(pick[1])
		best = maxi(best, g.round_num)
	print("  best round reached by random greedy play: ", best)
	check(best >= 2, "random greedy play can clear round 1")
