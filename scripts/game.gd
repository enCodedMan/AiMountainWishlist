extends RefCounted
## Run state: rounds, turns, jump-chain scoring, the enemy bot, cards and the shop.

const Board = preload("res://scripts/board.gd")
const Relics = preload("res://scripts/relics.gd")
const Content = preload("res://scripts/content.gd")

const BASE_TURNS := 5
const BASE_PAWNS := 4
const JUMP_CHIPS := 10
const GOLD_CHIPS := 30
const RED_MULT := 2
const REROLL_COST := 1
const SHOP_RELICS := 3
const SHOP_CARDS := 2
const SHOP_TRAINING := 2

var rng := RandomNumberGenerator.new()
var board: Board
var round_num := 1
var score := 0
var target := 0
var turns_left := 0
var money := 0
var relics: Array = []
var hand: Array = []  # card ids, max Content.HAND_SIZE
var levels := {}  # {"pawn": {"chips": 0, "mult": 0, "coins": 0}, "king": {...}}
var training_bought := {}  # training id -> times bought
var state := "play"  # play | shop | lost
var selected := Vector2i(-1, -1)
var in_chain := false
var chain_jumps := 0
var chain_chips := 0
var chain_mult := 0
var double_next := false
var chains_this_round := 0
var last_gain := 0
var shop: Array = []  # [{"kind": "relic" | "card" | "train", "id": String}]
var message := ""
var bot_last_move: Array = []  # cells the bot moved through, for the UI


func new_run(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	round_num = 1
	money = 4
	relics = []
	hand = []
	training_bought = {}
	levels = {}
	for piece in ["pawn", "king"]:
		levels[piece] = {"chips": 0, "mult": 0, "coins": 0}
	start_round()


static func target_for(r: int) -> int:
	return int(round(100.0 * pow(1.5, r - 1) / 10.0)) * 10


func has(id: String) -> bool:
	return relics.has(id)


func start_round() -> void:
	score = 0
	target = target_for(round_num)
	turns_left = BASE_TURNS + (1 if has("patience") else 0)
	chains_this_round = 0
	last_gain = 0
	double_next = false
	bot_last_move = []
	_reset_chain()
	board = _generate_board()
	state = "play"
	var drew := ""
	if hand.size() < Content.HAND_SIZE:
		var ids := Content.CARDS.keys()
		var card: String = ids[rng.randi_range(0, ids.size() - 1)]
		hand.append(card)
		drew = ". Drew %s" % Content.CARDS[card].name
	message = "Round %d: score %d in %d turns%s" % [round_num, target, turns_left, drew]


func _generate_board() -> Board:
	var b := Board.new()
	var home := b.dark_cells_in_rows([Board.SIZE - 2, Board.SIZE - 1])
	_shuffle(home)
	var pawns := mini(BASE_PAWNS + (1 if has("recruit") else 0), home.size())
	for i in pawns:
		b.set_cell(home[i], Board.PAWN)
	var field := b.dark_cells_in_rows([0, 1, 2, 3])
	_shuffle(field)
	var foes := mini(4 + round_num, field.size() - 3)
	for i in foes:
		b.set_cell(field[i], Board.FOE)
	# Bonus tiles go on empty dark cells in the field.
	var bonus := [Board.Tile.GOLD, Board.Tile.GOLD, Board.Tile.RED]
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
	board.set_cell(from, Board.EMPTY)
	board.set_cell(to, piece)
	if is_jump:
		board.set_cell((from + to) / 2, Board.EMPTY)
		_score_jump(piece, to)
	var promoted := piece == Board.PAWN and to.y == 0
	if promoted:
		board.set_cell(to, Board.KING)
		if has("boom"):
			_coronation_blast(to)
	if is_jump and not promoted and not board.jumps_from(to).is_empty():
		in_chain = true
		selected = to
		message = "Chain! Keep jumping"
		return
	_end_move()


func _score_jump(piece: int, landing: Vector2i) -> void:
	var lv: Dictionary = levels["king" if piece == Board.KING else "pawn"]
	chain_jumps += 1
	chain_chips += JUMP_CHIPS + lv.chips
	chain_mult += 1 + lv.mult
	money += lv.coins
	if has("heavy"):
		chain_chips += 5
	if has("crown") and piece == Board.KING:
		chain_chips += 15
	if has("opener") and chain_jumps == 1:
		chain_mult += 2
	match board.get_tile(landing):
		Board.Tile.GOLD:
			chain_chips += GOLD_CHIPS * (2 if has("goldrush") else 1)
			board.set_tile(landing, Board.Tile.NONE)
		Board.Tile.RED:
			chain_mult += RED_MULT
			board.set_tile(landing, Board.Tile.NONE)
	if has("third") and chain_jumps % 3 == 0:
		chain_mult *= 2


func _coronation_blast(p: Vector2i) -> void:
	for d in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		var q: Vector2i = p + d
		if board.in_bounds(q) and Board.is_foe(board.get_cell(q)):
			board.set_cell(q, Board.EMPTY)
			chain_chips += 20
			chain_mult += 1


func _end_move() -> void:
	last_gain = 0
	if chain_jumps > 0 or chain_chips > 0:
		if has("momentum"):
			chain_mult += chains_this_round
		var mult := maxi(chain_mult, 1)
		if double_next:
			mult *= 2
			double_next = false
		last_gain = chain_chips * mult
		score += last_gain
		if chain_jumps >= 2:
			chains_this_round += 1
		message = "%d chips x %d mult = %d" % [chain_chips, mult, last_gain]
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
		message = "Out of turns on round %d" % round_num
		return
	_bot_turn()
	if board.positions_of(Board.is_player).is_empty():
		state = "lost"
		message = "Your pieces were wiped out"


func _win_round() -> void:
	var earned := 3 + turns_left
	if has("interest"):
		earned += mini(money / 5, 5)
	money += earned
	message = "Round cleared! +$%d" % earned
	state = "shop"
	roll_shop()


func _spawn_wave() -> void:
	for p in board.dark_cells_in_rows([0]):
		if board.get_cell(p) == Board.EMPTY:
			board.set_cell(p, Board.FOE)


# --- Enemy bot ---------------------------------------------------------------

## Chance the bot plays a random legal move instead of its best one. Drops each round.
func bot_blunder_chance() -> float:
	return maxf(0.5 - 0.1 * (round_num - 1), 0.1)


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
	apply_bot_move(board, pick)
	bot_last_move = [pick.from] + pick.path
	if not pick.captured.is_empty():
		message += "  Bot took %d!" % pick.captured.size()


# --- Cards ---------------------------------------------------------------------

func use_card(i: int) -> bool:
	if state != "play" or i < 0 or i >= hand.size():
		return false
	var id: String = hand[i]
	match id:
		"double":
			double_next = true
		"overtime":
			turns_left += 1
		"reinforce":
			var spots := board.dark_cells_in_rows([Board.SIZE - 1]).filter(func(p): return board.get_cell(p) == Board.EMPTY)
			if spots.is_empty():
				message = "No room on your back row"
				return false
			board.set_cell(spots[rng.randi_range(0, spots.size() - 1)], Board.PAWN)
		"coronation":
			if selected.x < 0 or board.get_cell(selected) != Board.PAWN:
				message = "Select a pawn first"
				return false
			board.set_cell(selected, Board.KING)
		"cannonball":
			var foes := board.positions_of(Board.is_foe)
			if foes.is_empty():
				return false
			foes.sort_custom(func(a, b): return a.y > b.y)
			board.set_cell(foes[0], Board.EMPTY)
		"goldrain":
			var empty := board.dark_cells_in_rows(range(Board.SIZE)).filter(
				func(p): return board.get_cell(p) == Board.EMPTY and board.get_tile(p) == Board.Tile.NONE)
			_shuffle(empty)
			for p in empty.slice(0, 2):
				board.set_tile(p, Board.Tile.GOLD)
	hand.remove_at(i)
	message = "Used %s" % Content.CARDS[id].name
	return true


# --- Shop ----------------------------------------------------------------------

func roll_shop() -> void:
	shop = []
	var pool: Array = []
	for id in Relics.ALL:
		if not has(id):
			pool.append(id)
	_shuffle(pool)
	for id in pool.slice(0, SHOP_RELICS):
		shop.append({"kind": "relic", "id": id})
	var cards := Content.CARDS.keys()
	_shuffle(cards)
	for id in cards.slice(0, SHOP_CARDS):
		shop.append({"kind": "card", "id": id})
	var train := Content.TRAINING.keys()
	_shuffle(train)
	for id in train.slice(0, SHOP_TRAINING):
		shop.append({"kind": "train", "id": id})


func item_info(item: Dictionary) -> Dictionary:
	match item.kind:
		"relic":
			return Relics.ALL[item.id]
		"card":
			return Content.CARDS[item.id]
	return Content.TRAINING[item.id]


func item_cost(item: Dictionary) -> int:
	var cost: int = item_info(item).cost
	if item.kind == "train":
		cost += Content.TRAINING_COST_STEP * int(training_bought.get(item.id, 0))
	return cost


func can_buy(i: int) -> bool:
	if state != "shop" or i < 0 or i >= shop.size():
		return false
	if shop[i].kind == "card" and hand.size() >= Content.HAND_SIZE:
		return false
	return money >= item_cost(shop[i])


func buy(i: int) -> bool:
	if not can_buy(i):
		return false
	var item: Dictionary = shop[i]
	money -= item_cost(item)
	match item.kind:
		"relic":
			relics.append(item.id)
		"card":
			hand.append(item.id)
		"train":
			var t: Dictionary = Content.TRAINING[item.id]
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
