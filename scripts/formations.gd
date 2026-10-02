extends RefCounted
## Hand-placed enemy formations. Enemies use dark squares in rows 0-2
## (row 0 x=1,3,5; row 1 x=0,2,4; row 2 x=1,3,5). "k" marks a king.
## Later antes add pieces to the back rows, so a formation stays recognisable
## while getting tougher. Enemy kings only appear where a formation places one.

const SMALL := [
	{"name": "Scouts", "pieces": [[0, 1, "p"], [4, 1, "p"], [3, 0, "p"]]},
	{"name": "Picket", "pieces": [[1, 2, "p"], [5, 2, "p"], [3, 0, "p"]]},
	{"name": "Column", "pieces": [[3, 0, "p"], [2, 1, "p"], [3, 2, "p"]]},
	{"name": "Outriders", "pieces": [[1, 0, "p"], [5, 0, "p"], [2, 1, "p"]]},
]

const BIG := [
	{"name": "Wedge", "pieces": [[1, 0, "p"], [3, 0, "p"], [5, 0, "p"], [2, 1, "p"]]},
	{"name": "Line", "pieces": [[0, 1, "p"], [2, 1, "p"], [4, 1, "p"], [3, 0, "p"]]},
	{"name": "Pincer", "pieces": [[1, 0, "p"], [5, 0, "p"], [0, 1, "p"], [4, 1, "p"]]},
	{"name": "Spearhead", "pieces": [[3, 0, "p"], [2, 1, "p"], [4, 1, "p"], [3, 2, "p"]]},
]

const BOSS := [
	{"name": "Phalanx", "pieces": [[1, 0, "p"], [3, 0, "p"], [0, 1, "p"], [2, 1, "p"], [4, 1, "p"]]},
	{"name": "Crown Guard", "pieces": [[3, 0, "k"], [1, 0, "p"], [5, 0, "p"], [2, 1, "p"], [4, 1, "p"]]},
	{"name": "Hammer", "pieces": [[1, 0, "p"], [3, 0, "p"], [2, 1, "p"], [1, 2, "p"], [3, 2, "p"]]},
]

## Fill order for extra enemies at higher antes: back row first, then middle, then front.
const FILL := [[1, 0], [3, 0], [5, 0], [0, 1], [2, 1], [4, 1], [1, 2], [3, 2], [5, 2]]


static func pool(stage: int) -> Array:
	return [SMALL, BIG, BOSS][stage]


## Returns [[x, y, "p"|"k"], ...] for a formation at a given ante.
static func build(f: Dictionary, ante: int) -> Array:
	var pieces: Array = []
	var taken := {}
	for p in f.pieces:
		pieces.append(p.duplicate())
		taken[Vector2i(p[0], p[1])] = true
	var extra := ante - 1
	for c in FILL:
		if extra <= 0:
			break
		if not taken.has(Vector2i(c[0], c[1])):
			pieces.append([c[0], c[1], "p"])
			taken[Vector2i(c[0], c[1])] = true
			extra -= 1
	return pieces
