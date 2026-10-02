extends RefCounted
## Run state: rounds, turns, jump-chain scoring, passive cards, the enemy bot and the shop.

const Board = preload("res://scripts/board.gd")
const Cards = preload("res://scripts/cards.gd")

const BASE_TURNS := 5
const BASE_PAWNS := 4
const JUMP_CHIPS := 10
const GOLD_CHIPS := 30
const RED_MULT := 2
const REROLL_COST := 1
const SHOP_CARDS := 3
const SHOP_TRAINING := 2
const RARITY_WEIGHTS := [70, 25, 5]
const WIN_ANTE := 8
const ANTE_BASE := [100, 200, 350, 600, 1000, 1600, 2500, 4000]
const STAGE_SCALE := [1.0, 1.5, 2.0]
const STAGE_NAMES := ["Small", "Big", "Boss"]
const STAGE_REWARD := [3, 4, 5]
const BOSSES := {
	"swift": {"name": "Swift", "desc": "The bot moves twice each turn"},
	"short": {"name": "Short Fuse", "desc": "You get 1 fewer turn"},
	"crowned": {"name": "Crowned", "desc": "Every enemy starts as a king"},
	"wall": {"name": "The Wall", "desc": "3 extra enemies"},
	"barren": {"name": "Barren", "desc": "No gold or red squares"},
	"silence": {"name": "Silence", "desc": "Your leftmost card is disabled"},
}

var rng := RandomNumberGenerator.new()
var board: Board
var round_num := 1
var score := 0
var target := 0
var turns_left := 0
var max_turns := 0
var money := 0
var cards: Array = []  # [{"id": String, "n": int}] in trigger order; n is per-card state
var levels := {}  # {"pawn": {"chips", "mult", "coins"}, "king": {...}}
var training_bought := {}
var state := "play"  # play | shop | lost | won
var boss := ""  # active (or, in the shop, upcoming) boss rule id
var endless := false
## Cards the shop may offer. Empty means every card (used by tests).
var unlocked: Array = []
var run_stats := {}
var selected := Vector2i(-1, -1)
var in_chain := false
var chain_jumps := 0
var chain_chips := 0
var chain_mult := 0
var chain_xmult := 1.0
var chain_captured_king := false
var chains_this_round := 0
var last_gain := 0
var last_chips := 0
var last_mult := 0
var shop: Array = []  # [{"kind": "card" | "train", "id": String}]
var message := ""
var bot_last_move: Array = []
## Card triggers since the UI last read them: [{"slot": int, "text": String}]
var fx: Array = []
## Visual events for the UI to animate, in order:
## {"type": "move", "by": "player"|"bot", "piece", "path": [cells], "captured": [cells], "ctypes": [ints]}
## {"type": "score", "gain", "big": bool} | {"type": "win"} | {"type": "lost"}
var events: Array = []


func new_run(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	round_num = 1
	endless = false
	run_stats = {"max_chain": 0, "captures": 0, "king_captures": 0, "crowns": 0, "lost": 0, "best_move": 0, "lone_clear": false}
	boss = ""
	money = 4
	cards = []
	training_bought = {}
	levels = {}
	for piece in ["pawn", "king"]:
		levels[piece] = {"chips": 0, "mult": 0, "coins": 0}
	start_round()


static func ante_of(r: int) -> int:
	return (r - 1) / 3 + 1


static func stage_of(r: int) -> int:
	return (r - 1) % 3


static func target_for(r: int) -> int:
	var a := ante_of(r)
	var base: float = ANTE_BASE[mini(a, WIN_ANTE) - 1] * pow(1.6, maxi(a - WIN_ANTE, 0))
	return int(round(base * STAGE_SCALE[stage_of(r)] / 10.0)) * 10


func ante() -> int:
	return ante_of(round_num)


func stage() -> int:
	return stage_of(round_num)


func is_boss(id: String) -> bool:
	return stage() == 2 and boss == id


func _roll_boss() -> void:
	var ids := BOSSES.keys()
	boss = ids[rng.randi_range(0, ids.size() - 1)]


func has(id: String) -> bool:
	return cards.any(func(c): return c.id == id)


func start_round() -> void:
	score = 0
	target = target_for(round_num)
	if stage() == 2 and boss == "":
		_roll_boss()
	elif stage() != 2:
		boss = ""
	max_turns = BASE_TURNS - (1 if is_boss("short") else 0)
	turns_left = max_turns
	chains_this_round = 0
	last_gain = 0
	bot_last_move = []
	_reset_chain()
	board = _generate_board()
	state = "play"
	message = "Score %d in %d turns" % [target, turns_left]
	if stage() == 2:
		message = "Boss: %s. %s" % [BOSSES[boss].name, BOSSES[boss].desc]
	_trigger("round_start", {})


func _generate_board() -> Board:
	var b := Board.new()
	var home := b.dark_cells_in_rows([Board.SIZE - 2, Board.SIZE - 1])
	_shuffle(home)
	for i in mini(BASE_PAWNS, home.size()):
		b.set_cell(home[i], Board.PAWN)
	var field := b.dark_cells_in_rows([0, 1, 2, 3])
	_shuffle(field)
	var foes := mini(4 + ante() + stage() + (3 if is_boss("wall") else 0), field.size() - 3)
	for i in foes:
		b.set_cell(field[i], Board.FOE_KING if is_boss("crowned") else Board.FOE)
	var bonus := [] if is_boss("barren") else [Board.Tile.GOLD, Board.Tile.GOLD, Board.Tile.RED]
	for i in bonus.size():
		b.set_tile(field[foes + i], bonus[i])
	return b


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = arr[i]
		arr[i] = arr[j]
		arr[j] = t


func _reset_chain() -> void:
	in_chain = false
	chain_jumps = 0
	chain_chips = 0
	chain_mult = 0
	chain_xmult = 1.0
	chain_captured_king = false
	selected = Vector2i(-1, -1)


func legal_targets(p: Vector2i) -> Array:
	if not board.in_bounds(p) or not Board.is_player(board.get_cell(p)):
		return []
	var jumps := board.jumps_from(p)
	if in_chain:
		return jumps
	return jumps + board.steps_from(p)


## Handle a tap on a board cell. Returns true if anything changed.
func tap(p: Vector2i) -> bool:
	if state != "play" or not board.in_bounds(p):
		return false
	if not in_chain and Board.is_player(board.get_cell(p)):
		selected = p
		return true
	if selected.x >= 0 and legal_targets(selected).has(p):
		_move(selected, p)
		return true
	return false


func _move(from: Vector2i, to: Vector2i) -> void:
	var piece := board.get_cell(from)
	var is_jump := absi(to.x - from.x) == 2
	var mid_cell: Vector2i = (from + to) / 2
	events.append({"type": "move", "by": "player", "piece": piece, "path": [from, to],
		"captured": [mid_cell] if is_jump else [], "ctypes": [board.get_cell(mid_cell)] if is_jump else []})
	board.set_cell(from, Board.EMPTY)
	board.set_cell(to, piece)
	if is_jump:
		var mid: Vector2i = (from + to) / 2
		chain_captured_king = board.get_cell(mid) == Board.FOE_KING
		board.set_cell(mid, Board.EMPTY)
		_score_jump(piece, to)
	else:
		_trigger("step", {})
	if piece == Board.PAWN and to.y == 0:
		board.set_cell(to, Board.KING)
		run_stats.crowns += 1
		_trigger("promote", {"pos": to})
		_end_move()
		return
	if is_jump and not board.jumps_from(to).is_empty():
		in_chain = true
		selected = to
		message = "Chain! Keep jumping"
		return
	_end_move()


func _score_jump(piece: int, landing: Vector2i) -> void:
	var lv: Dictionary = levels["king" if piece == Board.KING else "pawn"]
	chain_jumps += 1
	run_stats.captures += 1
	if chain_captured_king:
		run_stats.king_captures += 1
	chain_chips += JUMP_CHIPS + lv.chips
	chain_mult += 1 + lv.mult
	money += lv.coins
	var tile := board.get_tile(landing)
	match tile:
		Board.Tile.GOLD:
			chain_chips += GOLD_CHIPS
		Board.Tile.RED:
			chain_mult += RED_MULT
	board.set_tile(landing, Board.Tile.NONE)
	_trigger("jump", {"piece": piece, "tile": tile, "king_captured": chain_captured_king})


func _end_move() -> void:
	last_gain = 0
	if chain_jumps > 0 or chain_chips > 0:
		_trigger("chain_end", {})
		last_chips = chain_chips
		last_mult = maxi(int(round(maxi(chain_mult, 1) * chain_xmult)), 1)
		last_gain = last_chips * last_mult
		score += last_gain
		run_stats.best_move = maxi(run_stats.best_move, last_gain)
		run_stats.max_chain = maxi(run_stats.max_chain, chain_jumps)
		events.append({"type": "score", "gain": last_gain, "big": last_gain * 2 >= target})
		if chain_jumps >= 2:
			chains_this_round += 1
		message = "+%d" % last_gain
	else:
		message = ""
	_reset_chain()
	turns_left -= 1
	if score >= target:
		_win_round()
		return
	if board.positions_of(Board.is_foe).is_empty():
		_spawn_wave()
	if turns_left <= 0:
		state = "lost"
		events.append({"type": "lost"})
		message = "Out of turns on ante %d" % ante()
		return
	_bot_turn()
	if is_boss("swift") and not board.positions_of(Board.is_player).is_empty():
		var first := bot_last_move
		_bot_turn()
		bot_last_move = first + bot_last_move
	if board.positions_of(Board.is_player).is_empty():
		state = "lost"
		events.append({"type": "lost"})
		message = "Your pieces were wiped out"


func _win_round() -> void:
	events.append({"type": "win"})
	if board.positions_of(Board.is_player).size() == 1:
		run_stats.lone_clear = true
	_trigger("round_end", {})
	var earned: int = STAGE_REWARD[stage()] + turns_left
	money += earned
	message = "Round cleared! +$%d" % earned
	boss = ""
	if stage_of(round_num + 1) == 2:
		_roll_boss()
	if stage() == 2 and ante() == WIN_ANTE and not endless:
		state = "won"
		message = "You beat ante %d!" % WIN_ANTE
		return
	state = "shop"
	roll_shop()


## After winning, keep playing harder antes.
func continue_endless() -> void:
	if state != "won":
		return
	endless = true
	state = "shop"
	roll_shop()


func _spawn_wave() -> void:
	for p in board.dark_cells_in_rows([0]):
		if board.get_cell(p) == Board.EMPTY:
			board.set_cell(p, Board.FOE)


# --- Passive cards -------------------------------------------------------------

## Run every card's effect for this event, left to right. Echo replays its left neighbour.
func _trigger(event: String, ctx: Dictionary) -> void:
	for i in cards.size():
		if i == 0 and is_boss("silence"):
			continue
		if cards[i].id == "echo":
			if i > 0 and cards[i - 1].id != "echo" and not (i == 1 and is_boss("silence")):
				var t := _card_effect(cards[i - 1], event, ctx)
				if t != "":
					fx.append({"slot": i, "text": "Echo " + t})
			continue
		var text := _card_effect(cards[i], event, ctx)
		if text != "":
			fx.append({"slot": i, "text": text})


## Applies one card's effect. Returns a short label if it triggered, else "".
func _card_effect(card: Dictionary, event: String, ctx: Dictionary) -> String:
	match [card.id, event]:
		["heavy", "jump"]:
			chain_chips += 6
			return "+6 chips"
		["opener", "jump"]:
			if chain_jumps == 1:
				chain_mult += 3
				return "+3 mult"
		["pawnpride", "jump"]:
			if ctx.piece == Board.PAWN:
				chain_chips += 8
				return "+8 chips"
		["royalblood", "jump"]:
			if ctx.piece == Board.KING:
				chain_mult += 3
				return "+3 mult"
		["bounty", "jump"]:
			money += 1
			return "+$1"
		["golddigger", "jump"]:
			if ctx.tile == Board.Tile.GOLD:
				money += 2
				return "+$2"
		["redcarpet", "jump"]:
			if ctx.tile == Board.Tile.RED:
				chain_mult += RED_MULT
				return "+%d mult" % RED_MULT
		["hattrick", "jump"]:
			if chain_jumps % 3 == 0:
				chain_xmult *= 2.0
				return "x2 mult"
		["snowball", "jump"]:
			chain_chips += 2 + card.n
			return "+%d chips" % (2 + card.n)
		["executioner", "jump"]:
			if ctx.king_captured:
				chain_xmult *= 2.0
				return "x2 mult"
		["longjump", "chain_end"]:
			if chain_jumps >= 3:
				chain_mult += 5
				return "+5 mult"
		["momentum", "chain_end"]:
			if chains_this_round > 0 and chain_jumps > 0:
				chain_mult += chains_this_round
				return "+%d mult" % chains_this_round
		["snowball", "chain_end"]:
			if chain_jumps >= 2:
				card.n += 1
				return "grew to +%d" % (2 + card.n)
		["patient", "chain_end"]:
			if card.n > 0 and chain_jumps > 0:
				chain_mult += card.n
				var banked: int = card.n
				card.n = 0
				return "+%d mult" % banked
		["martyr", "chain_end"]:
			if card.n > 0 and chain_jumps > 0:
				chain_mult += card.n
				return "+%d mult" % card.n
		["doubleagent", "chain_end"]:
			if chain_jumps > 0:
				chain_xmult *= 1.5
				return "x1.5 mult"
		["laststand", "chain_end"]:
			if chain_jumps > 0 and board.positions_of(Board.is_player).size() == 1:
				chain_xmult *= 3.0
				return "x3 mult"
		["cleansweep", "chain_end"]:
			if chain_jumps > 0 and board.positions_of(Board.is_foe).is_empty():
				chain_xmult *= 2.0
				money += 5
				return "x2 mult +$5"
		["patient", "step"]:
			card.n += 4
			return "banked %d" % card.n
		["blast", "promote"]:
			var hits := 0
			for d in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
				var q: Vector2i = ctx.pos + d
				if board.in_bounds(q) and Board.is_foe(board.get_cell(q)):
					board.set_cell(q, Board.EMPTY)
					hits += 1
			if hits > 0:
				chain_chips += 20 * hits
				return "Boom! +%d chips" % (20 * hits)
		["kingmaker", "promote"]:
			chain_chips += 30
			chain_mult += 10
			money += 3
			return "+30 chips +10 mult"
		["martyr", "lost_piece"]:
			card.n += 2 * int(ctx.count)
			return "now +%d mult" % card.n
		["reinforce", "round_start"]:
			var spots := board.dark_cells_in_rows([Board.SIZE - 1]).filter(func(p): return board.get_cell(p) == Board.EMPTY)
			if not spots.is_empty():
				board.set_cell(spots[rng.randi_range(0, spots.size() - 1)], Board.PAWN)
				return "+1 pawn"
		["redcarpet", "round_start"]:
			var empty := board.dark_cells_in_rows([1, 2, 3]).filter(
				func(p): return board.get_cell(p) == Board.EMPTY and board.get_tile(p) == Board.Tile.NONE)
			if not empty.is_empty():
				board.set_tile(empty[rng.randi_range(0, empty.size() - 1)], Board.Tile.RED)
				return "+1 red square"
		["piggy", "round_end"]:
			var gain := mini(money / 5, 5)
			if gain > 0:
				money += gain
				return "+$%d" % gain
	return ""


func take_events() -> Array:
	var out := events
	events = []
	return out


func take_fx() -> Array:
	var out := fx
	fx = []
	return out


func sell_value(slot: int) -> int:
	return maxi(int(Cards.ALL[cards[slot].id].cost * Cards.SELL_RATIO), 1)


func sell(slot: int) -> bool:
	if slot < 0 or slot >= cards.size() or state == "lost":
		return false
	money += sell_value(slot)
	cards.remove_at(slot)
	return true


## Swap a card with its left neighbour (trigger order matters).
func move_left(slot: int) -> bool:
	if slot <= 0 or slot >= cards.size():
		return false
	var t = cards[slot - 1]
	cards[slot - 1] = cards[slot]
	cards[slot] = t
	return true


# --- Enemy bot ---------------------------------------------------------------

## Chance the bot plays a random legal move instead of its best one. Drops each round.
func bot_blunder_chance() -> float:
	return maxf(0.45 - 0.03 * (round_num - 1), 0.1)


## All legal bot moves. Captures are mandatory (real checkers rules) and
## a capture always continues to the end of its jump chain.
func bot_moves(b: Board) -> Array:
	var captures: Array = []
	var steps: Array = []
	for p in b.positions_of(Board.is_foe):
		_collect_chains(b, p, p, [], [], captures)
		for to in b.steps_from(p):
			steps.append({"from": p, "path": [to], "captured": []})
	return captures if not captures.is_empty() else steps


func _collect_chains(b: Board, origin: Vector2i, at: Vector2i, path: Array, captured: Array, out: Array) -> void:
	var piece := b.get_cell(at)
	var extended := false
	for land in b.jumps_from(at):
		var mid: Vector2i = (at + land) / 2
		var mid_v := b.get_cell(mid)
		b.set_cell(at, Board.EMPTY)
		b.set_cell(mid, Board.EMPTY)
		b.set_cell(land, piece)
		_collect_chains(b, origin, land, path + [land], captured + [mid], out)
		b.set_cell(land, Board.EMPTY)
		b.set_cell(mid, mid_v)
		b.set_cell(at, piece)
		extended = true
	if not extended and not path.is_empty():
		out.append({"from": origin, "path": path, "captured": captured})


static func apply_bot_move(b: Board, m: Dictionary) -> void:
	var piece := b.get_cell(m.from)
	var to: Vector2i = m.path.back()
	b.set_cell(m.from, Board.EMPTY)
	for c in m.captured:
		b.set_cell(c, Board.EMPTY)
	if piece == Board.FOE and to.y == Board.SIZE - 1:
		piece = Board.FOE_KING
	b.set_cell(to, piece)


## Higher is better for the bot: take pieces (kings count double), crown,
## and don't leave the moved piece where the player can jump it.
func _bot_eval(m: Dictionary) -> float:
	var v := 0.0
	for c in m.captured:
		v += 20.0 if board.get_cell(c) == Board.KING else 10.0
	var after: Board = board.copy()
	apply_bot_move(after, m)
	var to: Vector2i = m.path.back()
	if board.get_cell(m.from) == Board.FOE and after.get_cell(to) == Board.FOE_KING:
		v += 6.0
	for q in after.positions_of(Board.is_player):
		for land in after.jumps_from(q):
			if (q + land) / 2 == to:
				v -= 8.0
	return v + rng.randf() * 2.0


func _bot_turn() -> void:
	bot_last_move = []
	var moves := bot_moves(board)
	if moves.is_empty():
		return
	var pick: Dictionary
	if rng.randf() < bot_blunder_chance():
		pick = moves[rng.randi_range(0, moves.size() - 1)]
	else:
		var best := -INF
		for m in moves:
			var v := _bot_eval(m)
			if v > best:
				best = v
				pick = m
	events.append({"type": "move", "by": "bot", "piece": board.get_cell(pick.from), "path": [pick.from] + pick.path,
		"captured": pick.captured, "ctypes": pick.captured.map(func(c): return board.get_cell(c))})
	apply_bot_move(board, pick)
	bot_last_move = [pick.from] + pick.path
	if not pick.captured.is_empty():
		message = "The bot took %d of your pieces" % pick.captured.size()
		run_stats.lost += pick.captured.size()
		_trigger("lost_piece", {"count": pick.captured.size()})


# --- Shop ----------------------------------------------------------------------

func _random_card_id(exclude: Array) -> String:
	var roll := rng.randi_range(1, 100)
	var rarity := 0 if roll <= RARITY_WEIGHTS[0] else (1 if roll <= RARITY_WEIGHTS[0] + RARITY_WEIGHTS[1] else 2)
	var pool: Array = []
	for id in Cards.ALL:
		if not has(id) and not exclude.has(id) and Cards.ALL[id].rarity == rarity and _offerable(id):
			pool.append(id)
	if pool.is_empty():
		for id in Cards.ALL:
			if not has(id) and not exclude.has(id) and _offerable(id):
				pool.append(id)
	return "" if pool.is_empty() else pool[rng.randi_range(0, pool.size() - 1)]


func _offerable(id: String) -> bool:
	return unlocked.is_empty() or unlocked.has(id)


func roll_shop() -> void:
	shop = []
	var picked: Array = []
	for i in SHOP_CARDS:
		var id := _random_card_id(picked)
		if id != "":
			picked.append(id)
			shop.append({"kind": "card", "id": id})
	var train := Cards.TRAINING.keys()
	_shuffle(train)
	for id in train.slice(0, SHOP_TRAINING):
		shop.append({"kind": "train", "id": id})


func item_info(item: Dictionary) -> Dictionary:
	return Cards.ALL[item.id] if item.kind == "card" else Cards.TRAINING[item.id]


func item_cost(item: Dictionary) -> int:
	var cost: int = item_info(item).cost
	if item.kind == "train":
		cost += Cards.TRAINING_COST_STEP * int(training_bought.get(item.id, 0))
	return cost


func can_buy(i: int) -> bool:
	if state != "shop" or i < 0 or i >= shop.size():
		return false
	if shop[i].kind == "card" and cards.size() >= Cards.SLOTS:
		return false
	return money >= item_cost(shop[i])


func buy(i: int) -> bool:
	if not can_buy(i):
		return false
	var item: Dictionary = shop[i]
	money -= item_cost(item)
	if item.kind == "card":
		cards.append({"id": item.id, "n": 0})
	else:
		var t: Dictionary = Cards.TRAINING[item.id]
		levels[t.piece][t.stat] += t.amount
		training_bought[item.id] = int(training_bought.get(item.id, 0)) + 1
	shop.remove_at(i)
	return true


func reroll() -> bool:
	if state != "shop" or money < REROLL_COST:
		return false
	money -= REROLL_COST
	roll_shop()
	return true


func next_round() -> void:
	if state != "shop":
		return
	round_num += 1
	start_round()
