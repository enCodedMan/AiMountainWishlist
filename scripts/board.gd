extends RefCounted
## Checkers board state and move rules. Pure logic, no drawing.
## Rules dictionaries (per side) can bend movement, e.g. from relics or boss rules:
##   back_capture: pawns may also capture backwards
##   flying_kings: kings move and capture any distance along a diagonal
##   sprint: pawns may step two squares forward on a quiet move
##   crown_row_offset: pawns crown this many rows early (0 = last row)
##   iron_kings: this side's kings can't be captured
##   fortress: this side's pieces on its own back two rows can't be captured
##   leapfrog: pieces may hop over a friendly piece on a quiet move
##   no_crown: this side's pawns never crown

const SIZE := 6

enum { EMPTY, PAWN, KING, FOE, FOE_KING }
enum Tile { NONE, GOLD, RED }

const DIAGONALS := [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]

var cells: Array = []  # cells[y][x], y = 0 is the enemy's back row
var tiles: Array = []  # kept for future board features


func _init() -> void:
	for y in SIZE:
		cells.append([])
		tiles.append([])
		for x in SIZE:
			cells[y].append(EMPTY)
			tiles[y].append(Tile.NONE)


func copy():
	var b = get_script().new()
	for y in SIZE:
		b.cells[y] = cells[y].duplicate()
		b.tiles[y] = tiles[y].duplicate()
	return b


static func is_player(v: int) -> bool:
	return v == PAWN or v == KING


static func is_foe(v: int) -> bool:
	return v == FOE or v == FOE_KING


static func is_king(v: int) -> bool:
	return v == KING or v == FOE_KING


static func is_dark(p: Vector2i) -> bool:
	return (p.x + p.y) % 2 == 1


## +1 for the player's side, -1 for the enemy's, 0 for empty.
static func side_of(v: int) -> int:
	return 1 if is_player(v) else (-1 if is_foe(v) else 0)


static func forward(side: int) -> int:
	return -1 if side == 1 else 1


static func back_row(side: int) -> int:
	return SIZE - 1 if side == 1 else 0


static func crown_of(v: int) -> int:
	return KING if v == PAWN else (FOE_KING if v == FOE else v)


func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < SIZE and p.y < SIZE


func get_cell(p: Vector2i) -> int:
	return cells[p.y][p.x]


func set_cell(p: Vector2i, v: int) -> void:
	cells[p.y][p.x] = v


func get_tile(p: Vector2i) -> int:
	return tiles[p.y][p.x]


func set_tile(p: Vector2i, t: int) -> void:
	tiles[p.y][p.x] = t


func positions_of(pred: Callable) -> Array:
	var out: Array = []
	for y in SIZE:
		for x in SIZE:
			if pred.call(cells[y][x]):
				out.append(Vector2i(x, y))
	return out


func count_side(side: int) -> int:
	var n := 0
	for y in SIZE:
		for x in SIZE:
			if side_of(cells[y][x]) == side:
				n += 1
	return n


func dark_cells_in_rows(rows: Array) -> Array:
	var out: Array = []
	for y in rows:
		for x in SIZE:
			var p := Vector2i(x, y)
			if is_dark(p):
				out.append(p)
	return out


## Does a pawn of `side` landing on row y get crowned?
static func crowns_at(side: int, y: int, rules: Dictionary) -> bool:
	if rules.get("no_crown", false):
		return false
	var off: int = rules.get("crown_row_offset", 0)
	return y <= off if side == 1 else y >= SIZE - 1 - off


func _immune(p: Vector2i, def_rules: Dictionary) -> bool:
	var v := get_cell(p)
	if def_rules.get("iron_kings", false) and is_king(v):
		return true
	if def_rules.get("fortress", false) and absi(p.y - back_row(side_of(v))) <= 1:
		return true
	return false


## Quiet moves for the piece at p.
func step_targets(p: Vector2i, rules: Dictionary) -> Array:
	var v := get_cell(p)
	var side := side_of(v)
	var out: Array = []
	for d in DIAGONALS:
		if not is_king(v) and d.y != forward(side):
			continue
		var q: Vector2i = p + d
		while in_bounds(q) and get_cell(q) == EMPTY:
			out.append(q)
			if not (is_king(v) and rules.get("flying_kings", false)):
				break
			q += d
		if not is_king(v) and rules.get("sprint", false):
			var one: Vector2i = p + d
			var two: Vector2i = p + d * 2
			if in_bounds(two) and get_cell(one) == EMPTY and get_cell(two) == EMPTY:
				out.append(two)
		if rules.get("leapfrog", false):
			var over: Vector2i = p + d
			var land: Vector2i = p + d * 2
			if in_bounds(land) and side_of(get_cell(over)) == side and get_cell(land) == EMPTY and not out.has(land):
				out.append(land)
	return out


## Single jumps from p: [{"to": Vector2i, "cap": Vector2i}].
func jump_targets(p: Vector2i, rules: Dictionary, def_rules: Dictionary) -> Array:
	var v := get_cell(p)
	var side := side_of(v)
	var out: Array = []
	for d in DIAGONALS:
		if not is_king(v) and d.y != forward(side) and not rules.get("back_capture", false):
			continue
		var q: Vector2i = p + d
		if is_king(v) and rules.get("flying_kings", false):
			while in_bounds(q) and get_cell(q) == EMPTY:
				q += d
		if not in_bounds(q) or side_of(get_cell(q)) != -side or _immune(q, def_rules):
			continue
		var land: Vector2i = q + d
		while in_bounds(land) and get_cell(land) == EMPTY:
			out.append({"to": land, "cap": q})
			if not (is_king(v) and rules.get("flying_kings", false)):
				break
			land += d
	return out


func side_has_capture(side: int, rules: Dictionary, def_rules: Dictionary) -> bool:
	for p in positions_of(func(v): return side_of(v) == side):
		if not jump_targets(p, rules, def_rules).is_empty():
			return true
	return false


## Every legal full move for a side, with mandatory capture and full jump chains.
## A move is {"from", "path": [cells], "caps": [cells]}. A pawn that crowns stops its chain.
func legal_moves(side: int, rules: Dictionary, def_rules: Dictionary) -> Array:
	var caps: Array = []
	var steps: Array = []
	for p in positions_of(func(v): return side_of(v) == side):
		_chains(p, p, [], [], caps, rules, def_rules)
		if caps.is_empty():
			for to in step_targets(p, rules):
				steps.append({"from": p, "path": [to], "caps": []})
	return caps if not caps.is_empty() else steps


func _chains(origin: Vector2i, at: Vector2i, path: Array, captured: Array, out: Array, rules: Dictionary, def_rules: Dictionary) -> void:
	var v := get_cell(at)
	var extended := false
	for j in jump_targets(at, rules, def_rules):
		var cap_v := get_cell(j.cap)
		set_cell(at, EMPTY)
		set_cell(j.cap, EMPTY)
		set_cell(j.to, v)
		var crowned: bool = not is_king(v) and crowns_at(side_of(v), j.to.y, rules)
		if crowned:
			out.append({"from": origin, "path": path + [j.to], "caps": captured + [j.cap]})
		else:
			_chains(origin, j.to, path + [j.to], captured + [j.cap], out, rules, def_rules)
		set_cell(j.to, EMPTY)
		set_cell(j.cap, cap_v)
		set_cell(at, v)
		extended = true
	if not extended and not path.is_empty():
		out.append({"from": origin, "path": path, "caps": captured})


## Applies a full move. Returns {"crowned": bool, "cap_types": [ints]}.
func apply_move(m: Dictionary, rules: Dictionary) -> Dictionary:
	var v := get_cell(m.from)
	var cap_types: Array = []
	for c in m.caps:
		cap_types.append(get_cell(c))
		set_cell(c, EMPTY)
	set_cell(m.from, EMPTY)
	var to: Vector2i = m.path.back()
	var crowned := false
	if not is_king(v) and crowns_at(side_of(v), to.y, rules):
		v = crown_of(v)
		crowned = true
	set_cell(to, v)
	return {"crowned": crowned, "cap_types": cap_types}
