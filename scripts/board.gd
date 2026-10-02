extends RefCounted
## Checkers board state and move rules. Pure logic, no drawing.

const SIZE := 6

enum { EMPTY, PAWN, KING, FOE, FOE_KING }
enum Tile { NONE, GOLD, RED }

var cells: Array = []  # cells[y][x], y = 0 is the enemy's back row
var tiles: Array = []


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


static func is_dark(p: Vector2i) -> bool:
	return (p.x + p.y) % 2 == 1


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


func dirs_for(piece: int) -> Array:
	match piece:
		PAWN:
			return [Vector2i(-1, -1), Vector2i(1, -1)]
		FOE:
			return [Vector2i(-1, 1), Vector2i(1, 1)]
		KING, FOE_KING:
			return [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
	return []


func _is_opponent(piece: int, other: int) -> bool:
	return is_foe(other) if is_player(piece) else is_player(other)


## Landing cells for single jumps from p.
func jumps_from(p: Vector2i) -> Array:
	var piece := get_cell(p)
	var out: Array = []
	for d in dirs_for(piece):
		var mid: Vector2i = p + d
		var land: Vector2i = p + d * 2
		if in_bounds(land) and _is_opponent(piece, get_cell(mid)) and get_cell(land) == EMPTY:
			out.append(land)
	return out


func steps_from(p: Vector2i) -> Array:
	var out: Array = []
	for d in dirs_for(get_cell(p)):
		var to: Vector2i = p + d
		if in_bounds(to) and get_cell(to) == EMPTY:
			out.append(to)
	return out


func positions_of(pred: Callable) -> Array:
	var out: Array = []
	for y in SIZE:
		for x in SIZE:
			if pred.call(cells[y][x]):
				out.append(Vector2i(x, y))
	return out


func dark_cells_in_rows(rows: Array) -> Array:
	var out: Array = []
	for y in rows:
		for x in SIZE:
			var p := Vector2i(x, y)
			if is_dark(p):
				out.append(p)
	return out
