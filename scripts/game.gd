extends RefCounted
## Run state. Each round is a real game of checkers against the bot: capture
## every enemy piece within the turn limit. Your army carries over between
## rounds (losses are permanent), relics bend the rules, and gold buys upgrades.

const Board = preload("res://scripts/board.gd")
const Relics = preload("res://scripts/relics.gd")
const Formations = preload("res://scripts/formations.gd")

const WIN_ANTE := 5
const BASE_TURNS := 8
const TURNS_PER_ENEMY := 3  # turn limit = BASE_TURNS + this per enemy piece
const BREAKTHROUGH_COST := 1  # turns lost when an enemy pawn reaches your back row
const HEARTS := 3
const ARMY_MAX := 6
const STAGE_NAMES := ["Small", "Big", "Boss"]
const STAGE_REWARD := [3, 4, 5]
const RECRUIT_COST := 3
const CROWN_COST := 5
const REROLL_COST := 1
const SHOP_RELICS := 3
const RARITY_WEIGHTS := [65, 28, 7]
## Your army's starting squares, front row first.
const HOME := [Vector2i(1, 4), Vector2i(3, 4), Vector2i(5, 4), Vector2i(2, 5), Vector2i(0, 5), Vector2i(4, 5)]

const BOSSES := {
	"swift": {"name": "Swift", "desc": "The bot moves twice each turn"},
	"crowned": {"name": "Crowned", "desc": "Enemies on the back row start as kings"},
	"mirror": {"name": "Mirror", "desc": "Enemy pawns can capture backwards"},
	"ambush": {"name": "Ambush", "desc": "The bot moves first"},
	"short": {"name": "Short Fuse", "desc": "A third fewer turns"},
	"silence": {"name": "Silence", "desc": "Your leftmost relic is disabled"},
}

const ARMIES := {
	"classic": {"name": "Classic", "desc": "4 pawns, $4, 3 lives", "pawns": 4, "kings": 0, "money": 4, "hearts": 3},
	"merchant": {"name": "Merchant", "desc": "3 pawns, $12, 3 lives", "pawns": 3, "kings": 0, "money": 12, "hearts": 3},
	"crowned": {"name": "Crowned Few", "desc": "1 king and 2 pawns, $4, 3 lives", "pawns": 2, "kings": 1, "money": 4, "hearts": 3},
	"militia": {"name": "Militia", "desc": "6 pawns, $0, 2 lives", "pawns": 6, "kings": 0, "money": 0, "hearts": 2},
}

var rng := RandomNumberGenerator.new()
var board: Board
var round_num := 1
var boss := ""
var formation: Dictionary = {}  # current, or (in the shop) next
var endless := false
var money := 0
var hearts := 0
var army: Array = []  # piece types (Board.PAWN / Board.KING) that carry between rounds
var relics: Array = []  # relic ids, left to right
var state := "play"  # play | shop | lost | won
var army_id := "classic"
var unlocked: Array = []  # relics the shop may offer; empty = all (tests)
var turns_left := 0
var max_turns := 0
var selected := Vector2i(-1, -1)
var in_chain := false
var move_caps: Array = []  # piece types captured during the current player move
var move_crowned := false
var phoenix_used := false
var shop: Array = []  # relic ids for sale
var message := ""
var last_result := ""  # "won" | "lost" for the shop header
var run_stats := {}
## Visual events for the UI, in order:
## {"type": "move", "by", "piece", "path", "captured", "ctypes"} | {"type": "zap", "cells", "ctypes"}
## {"type": "gold", "amount"} | {"type": "win"} | {"type": "lost"}
var events: Array = []
## Relic triggers for the UI: [{"slot", "text"}]
var fx: Array = []


func new_run(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var a: Dictionary = ARMIES[army_id]
	round_num = 1
	endless = false
	money = a.money
	hearts = a.hearts
	army = []
	for i in a.kings:
		army.append(Board.KING)
	for i in a.pawns:
		army.append(Board.PAWN)
	relics = []
	run_stats = {"captures": 0, "king_captures": 0, "crowns": 0, "lost": 0, "max_chain": 0, "bosses": 0}
	_pick_next()
	start_round()


static func ante_of(r: int) -> int:
	return (r - 1) / 3 + 1


static func stage_of(r: int) -> int:
	return (r - 1) % 3


func ante() -> int:
	return ante_of(round_num)


func stage() -> int:
	return stage_of(round_num)


func is_boss(id: String) -> bool:
	return stage() == 2 and boss == id


func has(id: String) -> bool:
	var i := relics.find(id)
	return i >= 0 and not _relic_disabled(i)


func _relic_disabled(i: int) -> bool:
	return i == 0 and is_boss("silence")


func _fx(id: String, text: String) -> void:
	fx.append({"slot": relics.find(id), "text": text})


func player_rules() -> Dictionary:
	return {
		"back_capture": has("backstab"), "flying_kings": has("flying"), "sprint": has("sprint"),
		"crown_row_offset": 1 if has("early") else 0, "iron_kings": has("iron"), "fortress": has("fortress"),
	}


func foe_rules() -> Dictionary:
	return {"back_capture": is_boss("mirror"), "no_crown": true}


## Choose the formation (and boss rule) for round_num.
func _pick_next() -> void:
	var pool: Array = Formations.pool(stage())
	formation = pool[rng.randi_range(0, pool.size() - 1)]
	boss = ""
	if stage() == 2:
		var ids := BOSSES.keys()
		boss = ids[rng.randi_range(0, ids.size() - 1)]


func enemy_layout() -> Array:
	return Formations.build(formation, ante())


func start_round() -> void:
	board = Board.new()
	for p in enemy_layout():
		var king: bool = p[2] == "k" or (is_boss("crowned") and p[1] == 0)
		board.set_cell(Vector2i(p[0], p[1]), Board.FOE_KING if king else Board.FOE)
	if has("recruiter") and army.size() < ARMY_MAX:
		army.append(Board.PAWN)
		_fx("recruiter", "+1 pawn")
	# Kings go to the back row, pawns up front.
	var order: Array = army.duplicate()
	order.sort_custom(func(a, b): return a == Board.PAWN and b == Board.KING)
	for i in mini(order.size(), HOME.size()):
		board.set_cell(HOME[i], order[i])
	max_turns = BASE_TURNS + TURNS_PER_ENEMY * board.count_side(-1)
	if is_boss("short"):
		max_turns = max_turns * 2 / 3
	turns_left = max_turns
	phoenix_used = false
	_reset_move()
	state = "play"
	message = "Capture every enemy piece"
	if stage() == 2:
		message = "Boss: %s. %s" % [BOSSES[boss].name, BOSSES[boss].desc]
	if has("scout"):
		var foes := board.positions_of(Board.is_foe)
		foes.sort_custom(func(a, b): return a.y > b.y)
		if not foes.is_empty():
			_zap([foes[0]])
			_fx("scout", "removed 1")
	if is_boss("ambush"):
		_bot_turn()
	_check_round_over()


func _reset_move() -> void:
	in_chain = false
	selected = Vector2i(-1, -1)
	move_caps = []
	move_crowned = false


# --- Player moves --------------------------------------------------------------

func must_capture() -> bool:
	return board.side_has_capture(1, player_rules(), foe_rules())


## Pieces the player may move right now (captures are mandatory).
func movable_pieces() -> Array:
	if in_chain:
		return [selected]
	var out: Array = []
	var forced := must_capture()
	for p in board.positions_of(Board.is_player):
		if forced:
			if not board.jump_targets(p, player_rules(), foe_rules()).is_empty():
				out.append(p)
		elif not board.step_targets(p, player_rules()).is_empty():
			out.append(p)
	return out


func legal_targets(p: Vector2i) -> Array:
	if state != "play" or not board.in_bounds(p) or not Board.is_player(board.get_cell(p)):
		return []
	if not movable_pieces().has(p):
		return []
	if in_chain or must_capture():
		return board.jump_targets(p, player_rules(), foe_rules()).map(func(j): return j.to)
	return board.step_targets(p, player_rules())


## Handle a tap on a board cell. Returns true if anything changed.
func tap(p: Vector2i) -> bool:
	if state != "play" or not board.in_bounds(p):
		return false
	if not in_chain and Board.is_player(board.get_cell(p)):
		if movable_pieces().has(p):
			selected = p
		else:
			message = "That piece can't move" if not must_capture() else "You must capture (it's checkers)"
		return true
	if selected.x >= 0 and legal_targets(selected).has(p):
		_player_step(selected, p)
		return true
	return false


func _player_step(from: Vector2i, to: Vector2i) -> void:
	var rules := player_rules()
	var v := board.get_cell(from)
	var jump: Dictionary = {}
	for j in board.jump_targets(from, rules, foe_rules()):
		if j.to == to:
			jump = j
	var caps: Array = [jump.cap] if not jump.is_empty() else []
	var ctypes: Array = [board.get_cell(jump.cap)] if not jump.is_empty() else []
	events.append({"type": "move", "by": "player", "piece": v, "path": [from, to], "captured": caps, "ctypes": ctypes})
	board.set_cell(from, Board.EMPTY)
	if not jump.is_empty():
		move_caps.append(ctypes[0])
		board.set_cell(jump.cap, Board.EMPTY)
	board.set_cell(to, v)
	if not Board.is_king(v) and Board.crowns_at(1, to.y, rules):
		board.set_cell(to, Board.KING)
		move_crowned = true
	elif not jump.is_empty() and not board.jump_targets(to, rules, foe_rules()).is_empty():
		in_chain = true
		selected = to
		message = "Keep jumping!"
		return
	_end_player_move(to)


func _end_player_move(at: Vector2i) -> void:
	var n := move_caps.size()
	var extra_turn := false
	message = ""
	if n > 0:
		run_stats.captures += n
		run_stats.max_chain = maxi(run_stats.max_chain, n)
		if has("bounty"):
			_gold(n)
			_fx("bounty", "+$%d" % n)
		if n >= 2 and has("hunter"):
			_gold(2)
			_fx("hunter", "+$2")
		if n >= 3 and has("lightning"):
			var foes := board.positions_of(Board.is_foe)
			if not foes.is_empty():
				_zap([foes[rng.randi_range(0, foes.size() - 1)]])
				_fx("lightning", "zap!")
		var kings := move_caps.filter(func(t): return t == Board.FOE_KING).size()
		run_stats.king_captures += kings
		if kings > 0 and has("executioner"):
			_gold(3 * kings)
			var pawns := board.positions_of(func(v): return v == Board.FOE)
			if not pawns.is_empty():
				_zap([pawns[rng.randi_range(0, pawns.size() - 1)]])
			_fx("executioner", "+$%d" % (3 * kings))
		if n >= 2 and has("momentum"):
			extra_turn = true
			_fx("momentum", "move again")
		message = "Captured %d" % n if n > 1 else ""
	if move_crowned:
		run_stats.crowns += 1
		if has("blast"):
			var hits: Array = []
			for d in Board.DIAGONALS:
				var q: Vector2i = at + d
				if board.in_bounds(q) and Board.is_foe(board.get_cell(q)):
					hits.append(q)
			if not hits.is_empty():
				_zap(hits)
				_fx("blast", "boom x%d" % hits.size())
		if has("rush"):
			extra_turn = true
			_fx("rush", "move again")
	_reset_move()
	turns_left -= 1
	if _check_round_over():
		return
	if extra_turn and turns_left > 0:
		message = "Move again!"
		return
	if turns_left <= 0:
		_lose_round("Out of turns")
		return
	_bot_turn()
	if is_boss("swift") and state == "play":
		_bot_turn()
	if state == "play" and not _check_round_over() and turns_left <= 0:
		_lose_round("Out of turns")


## Ends the round if one side is out of pieces or moves. Returns true if it ended.
func _check_round_over() -> bool:
	if state != "play":
		return true
	if board.count_side(-1) == 0:
		_win_round("Every enemy captured")
		return true
	if board.count_side(1) == 0:
		state = "lost"
		message = "Your army was wiped out"
		events.append({"type": "lost"})
		return true
	if board.legal_moves(-1, foe_rules(), player_rules()).is_empty():
		_win_round("The bot has no moves left")
		return true
	if board.legal_moves(1, player_rules(), foe_rules()).is_empty():
		_lose_round("You have no moves left")
		return true
	return false


func _gold(n: int) -> void:
	money += n
	events.append({"type": "gold", "amount": n})


func _zap(cells: Array) -> void:
	var types: Array = []
	for c in cells:
		types.append(board.get_cell(c))
		board.set_cell(c, Board.EMPTY)
	events.append({"type": "zap", "cells": cells, "ctypes": types})


func _survivors() -> Array:
	var out: Array = []
	for p in board.positions_of(Board.is_player):
		out.append(board.get_cell(p))
	return out


func _win_round(reason: String) -> void:
	army = _survivors()
	var earned: int = STAGE_REWARD[stage()]
	if has("greed") and turns_left > 0:
		earned += turns_left
		_fx("greed", "+$%d" % turns_left)
	if has("piggy"):
		var interest := mini(money / 5, 5)
		if interest > 0:
			earned += interest
			_fx("piggy", "+$%d" % interest)
	_gold(earned)
	if stage() == 2:
		run_stats.bosses += 1
	events.append({"type": "win"})
	last_result = "won"
	message = "%s! +$%d" % [reason, earned]
	if stage() == 2 and ante() == WIN_ANTE and not endless:
		state = "won"
		message = "You beat the final boss!"
		return
	_to_shop()


func _lose_round(reason: String) -> void:
	army = _survivors()
	hearts -= 1
	last_result = "lost"
	events.append({"type": "lost"})
	if hearts <= 0:
		state = "lost"
		message = reason + ". No lives left"
		return
	message = "%s. You lose a life (%d left) and must retry this round" % [reason, hearts]
	_to_shop(false)


## Opens the shop. After a loss the same round (formation and boss) is retried.
func _to_shop(advance := true) -> void:
	state = "shop"
	if advance:
		round_num += 1
		_pick_next()
	roll_shop()


## After winning, keep playing harder antes.
func continue_endless() -> void:
	if state != "won":
		return
	endless = true
	_to_shop()


# --- The bot -----------------------------------------------------------------------

## How many moves ahead the bot looks. Grows with ante; bosses think one deeper.
func bot_depth() -> int:
	if ante() == 1 and stage() == 0:
		return 1
	return mini(2 + (1 if ante() >= 3 else 0) + (1 if stage() == 2 and ante() >= 2 else 0), 4)


func bot_blunder_chance() -> float:
	return 0.3 if ante() == 1 and stage() == 0 else 0.0


func bot_choose(moves: Array) -> Dictionary:
	if rng.randf() < bot_blunder_chance():
		return moves[rng.randi_range(0, moves.size() - 1)]
	var best: Dictionary = moves[0]
	var best_v := -INF
	for m in moves:
		var b: Board = board.copy()
		b.apply_move(m, foe_rules())
		var v := _search(b, 1, bot_depth() - 1, -INF, INF) + rng.randf() * 0.5
		if v > best_v:
			best_v = v
			best = m
	return best


## Minimax with alpha-beta, scored from the bot's side.
func _search(b: Board, side: int, depth: int, alpha: float, beta: float) -> float:
	var pr := player_rules()
	var fr := foe_rules()
	var moves := b.legal_moves(side, fr if side == -1 else pr, pr if side == -1 else fr)
	if moves.is_empty():
		return -1000.0 - depth if side == -1 else 1000.0 + depth
	if depth <= 0:
		return _eval(b)
	if side == -1:
		var v := -INF
		for m in moves:
			var c: Board = b.copy()
			c.apply_move(m, fr)
			v = maxf(v, _search(c, 1, depth - 1, alpha, beta))
			alpha = maxf(alpha, v)
			if alpha >= beta:
				break
		return v
	var w := INF
	for m in moves:
		var c: Board = b.copy()
		c.apply_move(m, pr)
		w = minf(w, _search(c, -1, depth - 1, alpha, beta))
		beta = minf(beta, w)
		if alpha >= beta:
			break
	return w


func _eval(b: Board) -> float:
	var v := 0.0
	for y in Board.SIZE:
		for x in Board.SIZE:
			match b.cells[y][x]:
				Board.FOE:
					v += 10.0 + y
				Board.FOE_KING:
					v += 24.0
				Board.PAWN:
					v -= 10.0 + (Board.SIZE - 1 - y)
				Board.KING:
					v -= 24.0
	return v


func _bot_turn() -> void:
	var moves := board.legal_moves(-1, foe_rules(), player_rules())
	if moves.is_empty():
		return
	var m := bot_choose(moves)
	var piece := board.get_cell(m.from)
	var cap_cells: Array = m.caps
	var res := board.apply_move(m, foe_rules())
	events.append({"type": "move", "by": "bot", "piece": piece, "path": [m.from] + m.path, "captured": cap_cells, "ctypes": res.cap_types})
	message = ""
	_breakthrough(m.path.back())
	if cap_cells.is_empty():
		return
	run_stats.lost += cap_cells.size()
	message = "The bot took %d of your pieces" % cap_cells.size()
	if has("bomb"):
		var hits: Array = []
		for c in cap_cells:
			for d in Board.DIAGONALS:
				var q: Vector2i = c + d
				if board.in_bounds(q) and Board.is_foe(board.get_cell(q)) and not hits.has(q):
					hits.append(q)
		if not hits.is_empty():
			_zap(hits)
			_fx("bomb", "boom x%d" % hits.size())
	if has("phoenix") and not phoenix_used:
		for p in HOME.slice(3) + HOME.slice(0, 3):
			if board.get_cell(p) == Board.EMPTY:
				board.set_cell(p, res.cap_types[0])
				phoenix_used = true
				_fx("phoenix", "revived")
				break


## Enemy pawns never crown. One that reaches your back row breaks through:
## it leaves the board and costs you turns (Undertow turns that into gold).
func _breakthrough(at: Vector2i) -> void:
	if board.get_cell(at) != Board.FOE or at.y != Board.SIZE - 1:
		return
	_zap([at])
	if has("undertow"):
		_gold(2)
		_fx("undertow", "+$2")
		message = "An enemy broke through and drowned (+$2)"
		return
	turns_left -= BREAKTHROUGH_COST
	message = "An enemy broke through! -%d turns" % BREAKTHROUGH_COST


# --- Shop ------------------------------------------------------------------------

func _offerable(id: String) -> bool:
	return not relics.has(id) and (unlocked.is_empty() or unlocked.has(id))


func _random_relic(exclude: Array) -> String:
	var roll := rng.randi_range(1, 100)
	var rarity := 0 if roll <= RARITY_WEIGHTS[0] else (1 if roll <= RARITY_WEIGHTS[0] + RARITY_WEIGHTS[1] else 2)
	var pool: Array = []
	for id in Relics.ALL:
		if _offerable(id) and not exclude.has(id) and Relics.ALL[id].rarity == rarity:
			pool.append(id)
	if pool.is_empty():
		for id in Relics.ALL:
			if _offerable(id) and not exclude.has(id):
				pool.append(id)
	return "" if pool.is_empty() else pool[rng.randi_range(0, pool.size() - 1)]


func roll_shop() -> void:
	shop = []
	for i in SHOP_RELICS:
		var id := _random_relic(shop)
		if id != "":
			shop.append(id)


func relic_cost(id: String) -> int:
	return Relics.ALL[id].cost


func can_buy(i: int) -> bool:
	return state == "shop" and i >= 0 and i < shop.size() and relics.size() < Relics.SLOTS and money >= relic_cost(shop[i])


func buy(i: int) -> bool:
	if not can_buy(i):
		return false
	money -= relic_cost(shop[i])
	relics.append(shop[i])
	shop.remove_at(i)
	return true


func can_recruit() -> bool:
	return state == "shop" and army.size() < ARMY_MAX and money >= RECRUIT_COST


func recruit() -> bool:
	if not can_recruit():
		return false
	money -= RECRUIT_COST
	army.append(Board.PAWN)
	return true


func can_crown() -> bool:
	return state == "shop" and army.has(Board.PAWN) and money >= CROWN_COST


func crown_pawn() -> bool:
	if not can_crown():
		return false
	money -= CROWN_COST
	army[army.find(Board.PAWN)] = Board.KING
	return true


func reroll() -> bool:
	if state != "shop" or money < REROLL_COST:
		return false
	money -= REROLL_COST
	roll_shop()
	return true


func sell_value(slot: int) -> int:
	return maxi(int(Relics.ALL[relics[slot]].cost * Relics.SELL_RATIO), 1)


func sell(slot: int) -> bool:
	if slot < 0 or slot >= relics.size() or state != "shop":
		return false
	money += sell_value(slot)
	relics.remove_at(slot)
	return true


## Swap a relic with its left neighbour (matters for Silence).
func move_left(slot: int) -> bool:
	if slot <= 0 or slot >= relics.size():
		return false
	var t = relics[slot - 1]
	relics[slot - 1] = relics[slot]
	relics[slot] = t
	return true


func next_round() -> void:
	if state != "shop":
		return
	if army.is_empty():
		state = "lost"
		message = "You have no army left"
		return
	start_round()


func take_events() -> Array:
	var out := events
	events = []
	return out


func take_fx() -> Array:
	var out := fx
	fx = []
	return out
