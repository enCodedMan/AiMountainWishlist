extends SceneTree
## Headless logic tests: godot --headless --path . -s tests/run_tests.gd

const Game = preload("res://scripts/game.gd")
const Board = preload("res://scripts/board.gd")
const Profile = preload("res://scripts/profile.gd")

var failures := 0
var ran_random := false


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
	test_training_stacks_and_costs_more()
	test_cards()
	test_bot_must_capture_and_chains()
	test_antes_and_bosses()
	test_profile_unlocks()
	test_out_of_turns_loses()
	test_random_runs_do_not_crash()
	if not ran_random:
		failures += 1
		print("  FAIL random play did not finish (script error?)")
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
	print("hat trick card")
	var g := blank_game()
	g.cards = [{"id": "hattrick", "n": 0}]
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
	check(g.shop.size() == 5, "shop stocked")


func test_shop_buy_and_next_round() -> void:
	print("shop")
	var g := blank_game()
	g.state = "shop"
	g.money = 100
	g.roll_shop()
	check(g.shop.size() == 5, "shop has 3 cards and 2 training (got %d)" % g.shop.size())
	var id: String = g.shop[0].id
	check(g.buy(0), "buy card succeeds")
	check(g.has(id), "card owned")
	check(g.reroll(), "reroll succeeds")
	check(not g.shop.any(func(it): return it.kind == "card" and it.id == id), "owned card not re-offered")
	g.cards = []
	for i in 5:
		g.cards.append({"id": "heavy", "n": 0})
	g.shop = [{"kind": "card", "id": "opener"}]
	check(not g.can_buy(0), "can't buy a card with all 5 slots full")
	var before := g.money
	check(g.sell(0) and g.money == before + 2 and g.cards.size() == 4, "selling refunds half price")
	g.next_round()
	check(g.round_num == 2 and g.state == "play", "round 2 starts")
	check(g.target == 150, "round 2 target is 150 (got %d)" % g.target)


func test_training_stacks_and_costs_more() -> void:
	print("training")
	var g := blank_game()
	g.state = "shop"
	g.money = 100
	g.shop = [{"kind": "train", "id": "pawn_mult"}, {"kind": "train", "id": "pawn_mult"}]
	check(g.item_cost(g.shop[0]) == 4, "first Pawn Fervor costs $4")
	g.buy(0)
	check(g.item_cost(g.shop[0]) == 6, "second costs $6")
	g.buy(0)
	check(g.levels.pawn.mult == 2, "pawn mult level 2")
	g.state = "play"
	g.board = Board.new()
	g.board.set_cell(Vector2i(1, 5), Board.PAWN)
	g.board.set_cell(Vector2i(2, 4), Board.FOE)
	g.board.set_cell(Vector2i(5, 0), Board.FOE)
	g.tap(Vector2i(1, 5))
	g.tap(Vector2i(3, 3))
	check(g.score == 10 * 3, "pawn jump scores 10 chips x 3 mult (got %d)" % g.score)


func jump_once(g: Game) -> void:
	g.board.set_cell(Vector2i(1, 5), Board.PAWN)
	g.board.set_cell(Vector2i(2, 4), Board.FOE)
	g.board.set_cell(Vector2i(5, 0), Board.FOE)
	g.tap(Vector2i(1, 5))
	g.tap(Vector2i(3, 3))


func test_cards() -> void:
	print("passive cards")
	var g := blank_game()
	g.cards = [{"id": "heavy", "n": 0}, {"id": "opener", "n": 0}]
	jump_once(g)
	check(g.score == 16 * 4, "Heavy Crown + Opening Gambit: 16 chips x 4 mult (got %d)" % g.score)
	check(g.take_fx().size() == 2, "both cards report a trigger")

	g = blank_game()
	g.cards = [{"id": "heavy", "n": 0}, {"id": "echo", "n": 0}]
	jump_once(g)
	check(g.score == 22 * 1, "Echo retriggers Heavy Crown: 22 chips (got %d)" % g.score)

	g = blank_game()
	g.cards = [{"id": "patient", "n": 0}]
	g.board.set_cell(Vector2i(0, 5), Board.PAWN)
	g.board.set_cell(Vector2i(5, 0), Board.FOE)
	g.tap(Vector2i(0, 5))
	g.tap(Vector2i(1, 4))  # quiet move banks +4
	g.board = Board.new()
	jump_once(g)
	check(g.score == 10 * 5, "Patient Hand spends banked +4 mult (got %d)" % g.score)
	check(g.cards[0].n == 0, "bank emptied")

	g = blank_game()
	g.cards = [{"id": "doubleagent", "n": 0}]
	jump_once(g)
	check(g.score == 10 * 2, "Double Agent x1.5 on mult 1 rounds to 2 (got %d)" % g.score)

	g = blank_game()
	g.cards = [{"id": "martyr", "n": 0}]
	g._trigger("lost_piece", {"count": 2})
	check(g.cards[0].n == 4, "Martyr grows +2 per lost piece")
	jump_once(g)
	check(g.score == 10 * 5, "Martyr adds its mult (got %d)" % g.score)

	g = blank_game()
	g.cards = [{"id": "kingmaker", "n": 0}]
	g.board.set_cell(Vector2i(2, 1), Board.PAWN)
	g.board.set_cell(Vector2i(5, 4), Board.FOE)
	g.tap(Vector2i(2, 1))
	g.tap(Vector2i(1, 0))
	check(g.board.get_cell(Vector2i(1, 0)) == Board.KING, "pawn crowned")
	check(g.score == 30 * 10, "Kingmaker scores on a quiet crowning (got %d)" % g.score)


func test_bot_must_capture_and_chains() -> void:
	print("bot")
	var g := blank_game()
	g.board.set_cell(Vector2i(0, 1), Board.FOE)
	g.board.set_cell(Vector2i(1, 2), Board.PAWN)
	g.board.set_cell(Vector2i(3, 4), Board.PAWN)
	g.board.set_cell(Vector2i(5, 0), Board.FOE)
	var moves := g.bot_moves(g.board)
	check(moves.size() == 1, "capture is mandatory: only 1 legal move (got %d)" % moves.size())
	check(moves[0].captured.size() == 2 and moves[0].path.back() == Vector2i(4, 5), "bot double-jumps to (4,5)")
	g.round_num = 99  # no blunders
	g._bot_turn()
	check(g.board.get_cell(Vector2i(4, 5)) == Board.FOE_KING, "bot piece crowned on your back row")
	check(g.board.positions_of(Board.is_player).is_empty(), "both pawns taken")


func test_antes_and_bosses() -> void:
	print("antes and bosses")
	check(Game.target_for(1) == 100 and Game.target_for(3) == 200 and Game.target_for(4) == 200, "ante targets: 100, boss 200, ante 2 small 200")
	check(Game.target_for(24) == 8000, "ante 8 boss is 8000 (got %d)" % Game.target_for(24))
	check(Game.target_for(25) > Game.target_for(24) / 2, "endless keeps growing")
	var g := Game.new()
	g.new_run(3)
	g.round_num = 3
	g.boss = "short"
	g.start_round()
	check(g.turns_left == 4, "Short Fuse removes a turn")
	g.round_num = 3
	g.boss = "crowned"
	g.start_round()
	check(g.board.positions_of(func(v): return v == Board.FOE).is_empty(), "Crowned: all enemies are kings")
	g = blank_game()
	g.round_num = 3
	g.boss = "silence"
	g.cards = [{"id": "heavy", "n": 0}, {"id": "echo", "n": 0}]
	jump_once(g)
	check(g.score == 10, "Silence disables the leftmost card and its echo (got %d)" % g.score)
	# Winning the final boss ends the run in victory, then endless continues.
	g = blank_game()
	g.round_num = 24
	g.target = 10
	jump_once(g)
	check(g.state == "won", "beating ante 8 boss wins the run")
	g.continue_endless()
	check(g.state == "shop" and g.endless, "endless continues to the shop")
	g.next_round()
	check(g.ante() == 9 and g.state == "play", "ante 9 starts")
	# Next boss is known in the shop before round 3.
	g = blank_game()
	g.round_num = 2
	g.target = 10
	jump_once(g)
	check(g.state == "shop" and Game.BOSSES.has(g.boss), "upcoming boss is chosen in the shop")
	var b := g.boss
	g.next_round()
	check(g.boss == b and g.stage() == 2, "boss round uses the previewed boss")


func test_profile_unlocks() -> void:
	print("profile")
	var p := Profile.new()
	p.path = "user://test_profile.json"
	var g := blank_game()
	g.unlocked = p.data.unlocked.duplicate()
	g.state = "shop"
	for k in 30:
		g.roll_shop()
		for it in g.shop:
			if it.kind == "card" and not Profile.STARTER.has(it.id):
				check(false, "shop offered locked card " + it.id)
				return
	check(true, "shop only offers unlocked cards")
	g.run_stats.max_chain = 3
	var fresh := p.check_unlocks(g)
	check(fresh.has("hattrick") and g.unlocked.has("hattrick"), "3-jump chain unlocks Hat Trick")
	p.data.runs = 7
	p.save_profile()
	var q := Profile.new()
	q.path = p.path
	q.load_profile()
	check(q.data.runs == 7 and q.is_unlocked("hattrick"), "profile survives save and load")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p.path))


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
				for i in range(g.shop.size() - 1, -1, -1):
					g.buy(i)
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
	ran_random = true
	print("  best round reached by random greedy play: ", best)
	check(best >= 2, "random greedy play can clear round 1")
