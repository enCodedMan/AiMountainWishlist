extends RefCounted
## Run state: rounds, turns, jump-chain scoring, enemy turns and the shop.

const Board = preload("res://scripts/board.gd")
const Relics = preload("res://scripts/relics.gd")

const BASE_TURNS := 5
const BASE_PAWNS := 4
const JUMP_CHIPS := 10
const GOLD_CHIPS := 30
const RED_MULT := 2
const FOES_MOVED_PER_TURN := 2
const SHOP_SIZE := 3
const REROLL_COST := 1

var rng := RandomNumberGenerator.new()
var board: Board
var round_num := 1
var score := 0
var target := 0
var turns_left := 0
var money := 0
var relics: Array = []
var state := "play"  # play | shop | lost
var selected := Vector2i(-1, -1)
var in_chain := false
var chain_jumps := 0
var chain_chips := 0
var chain_mult := 0
var chains_this_round := 0
var last_gain := 0
var shop_offer: Array = []
var message := ""


func new_run(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	round_num = 1
	money = 4
	relics = []
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
	_reset_chain()
	board = _generate_board()
	state = "play"
	message = "Round %d: score %d in %d turns" % [round_num, target, turns_left]


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
	chain_jumps += 1
	chain_chips += JUMP_CHIPS
	chain_mult += 1
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
		last_gain = chain_chips * maxi(chain_mult, 1)
		score += last_gain
		if chain_jumps >= 2:
			chains_this_round += 1
		message = "%d chips x %d mult = %d" % [chain_chips, maxi(chain_mult, 1), last_gain]
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
	_enemy_turn()
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
	var row0 := board.dark_cells_in_rows([0])
	for p in row0:
		if board.get_cell(p) == Board.EMPTY:
			board.set_cell(p, Board.FOE)


## Dumb enemy AI: a few foes act per turn, capturing if they can, else stepping.
func _enemy_turn() -> void:
	var foes := board.positions_of(Board.is_foe)
	_shuffle(foes)
	var moved := 0
	for p in foes:
		if moved >= FOES_MOVED_PER_TURN:
			break
		var jumps := board.jumps_from(p)
		var options := jumps if not jumps.is_empty() else board.steps_from(p)
		if options.is_empty():
			continue
		var to: Vector2i = options[rng.randi_range(0, options.size() - 1)]
		var piece := board.get_cell(p)
		board.set_cell(p, Board.EMPTY)
		if absi(to.x - p.x) == 2:
			board.set_cell((p + to) / 2, Board.EMPTY)
		if piece == Board.FOE and to.y == Board.SIZE - 1:
			piece = Board.FOE_KING
		board.set_cell(to, piece)
		moved += 1


func roll_shop() -> void:
	var pool: Array = []
	for id in Relics.ALL:
		if not has(id):
			pool.append(id)
	_shuffle(pool)
	shop_offer = pool.slice(0, SHOP_SIZE)


func buy(id: String) -> bool:
	if state != "shop" or not shop_offer.has(id):
		return false
	var cost: int = Relics.ALL[id].cost
	if money < cost:
		return false
	money -= cost
	relics.append(id)
	shop_offer.erase(id)
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
