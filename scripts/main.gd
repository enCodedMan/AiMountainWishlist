extends Node2D
## Game UI: everything is drawn with _draw and hit-tested by hand.

const Game = preload("res://scripts/game.gd")
const Board = preload("res://scripts/board.gd")
const Cards = preload("res://scripts/cards.gd")

const W := 480.0
const H := 860.0
const CELL := 72.0
const ORIGIN := Vector2(24, 244)
const CARD_SIZE := Vector2(80, 100)
const CARD_GAP := 8.0

# Board colours (unchanged look)
const C_LIGHT := Color("e9d8b4")
const C_DARK := Color("8a5a3c")
const C_PLAYER := Color("f4f1ea")
const C_FOE := Color("c0392b")
const C_GOLD_TILE := Color("f1c40f")
const C_RED_TILE := Color("e74c3c")
const C_HILITE := Color(0.3, 0.9, 0.5, 0.55)
const C_BOT := Color(1.0, 0.4, 0.3, 0.35)

# UI palette
const C_BG := Color("13121c")
const C_PANEL := Color("1e1c2b")
const C_PANEL_HI := Color("292638")
const C_BORDER := Color("34314a")
const C_TEXT := Color("f4f1ea")
const C_MUTED := Color("9a96b0")
const C_ACCENT := Color("f5c542")
const C_CHIPS := Color("3b82f6")
const C_MULT := Color("ef4444")
const RARITY_COLORS := [Color("94a3b8"), Color("2dd4bf"), Color("a78bfa")]
const RARITY_NAMES := ["Common", "Uncommon", "Rare"]
const TAGS := {
	"heavy": "JUMP", "opener": "JUMP", "pawnpride": "JUMP", "royalblood": "JUMP", "bounty": "JUMP",
	"golddigger": "JUMP", "hattrick": "JUMP", "snowball": "JUMP", "executioner": "JUMP",
	"longjump": "CHAIN", "momentum": "CHAIN", "doubleagent": "CHAIN", "laststand": "CHAIN",
	"cleansweep": "CHAIN", "patient": "QUIET", "martyr": "LOSS", "blast": "CROWN", "kingmaker": "CROWN",
	"redcarpet": "ROUND", "reinforce": "ROUND", "piggy": "ROUND", "echo": "ECHO",
}

var game := Game.new()
var font: Font
var buttons: Array = []  # [Rect2, Callable]
var sel_card := -1  # selected owned card slot, for the detail bar
var shown_score := 0.0
var pulses := {}  # slot -> remaining seconds
var floaters: Array = []  # [{"slot", "text", "t"}]
var last_state := ""


func _ready() -> void:
	font = ThemeDB.fallback_font
	game.new_run()
	shown_score = game.score


func _process(delta: float) -> void:
	for f in game.take_fx():
		pulses[f.slot] = 0.35
		floaters.append({"slot": f.slot, "text": f.text, "t": 0.0})
	var busy := absf(shown_score - game.score) > 0.5 or not pulses.is_empty() or not floaters.is_empty()
	shown_score = lerpf(shown_score, game.score, minf(delta * 8.0, 1.0))
	if absf(shown_score - game.score) <= 0.5:
		shown_score = game.score
	for k in pulses.keys():
		pulses[k] -= delta
		if pulses[k] <= 0.0:
			pulses.erase(k)
	for f in floaters:
		f.t += delta
	floaters = floaters.filter(func(f): return f.t < 1.1)
	if busy:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var pos := get_local_mouse_position()
	for i in range(buttons.size() - 1, -1, -1):
		if buttons[i][0].has_point(pos):
			buttons[i][1].call()
			queue_redraw()
			return
	if game.state == "play":
		var cell := Vector2i(((pos - ORIGIN) / CELL).floor())
		if game.tap(cell):
			queue_redraw()


# --- Drawing helpers -----------------------------------------------------------

func _box(rect: Rect2, color: Color, radius := 12, border := Color.TRANSPARENT, border_w := 0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	draw_style_box(sb, rect)


func _text(s: String, pos: Vector2, size := 18, color := C_TEXT, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(font, pos, s, align, width, size, color)


func _wrap(s: String, pos: Vector2, width: float, size := 13, color := C_TEXT, lines := 3, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_multiline_string(font, pos, s, align, width, size, lines, color)


func _button(rect: Rect2, label: String, action: Callable, enabled := true, primary := false) -> void:
	var bg := C_ACCENT if primary else C_PANEL_HI
	var fg := C_BG if primary else C_TEXT
	if not enabled:
		bg = C_PANEL
		fg = C_MUTED.darkened(0.3)
	_box(rect, bg, 10, C_BORDER if not primary else bg, 0 if primary else 1)
	_text(label, rect.position + Vector2(0, rect.size.y / 2 + 6), 17, fg, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	if enabled:
		buttons.append([rect, action])


func _pill(rect: Rect2, label: String, color := C_TEXT) -> void:
	_box(rect, C_PANEL, int(rect.size.y / 2), C_BORDER, 1)
	_text(label, rect.position + Vector2(0, rect.size.y / 2 + 6), 16, color, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)


# --- Screens -------------------------------------------------------------------

func _draw() -> void:
	buttons.clear()
	if game.state != last_state:
		last_state = game.state
		floaters.clear()
		pulses.clear()
	draw_rect(Rect2(0, 0, W, H), C_BG)
	if game.state == "shop":
		_draw_shop()
		return
	_draw_top_bar()
	_draw_score_panel()
	_draw_chain_panel()
	_draw_board()
	_draw_card_row(Vector2(24, 708), true)
	_draw_detail_bar(Rect2(24, 816, W - 48, 38))
	if game.state == "lost":
		_draw_lost()
	elif game.state == "won":
		_draw_won()


func _draw_top_bar() -> void:
	_text("KINGJUMP", Vector2(24, 46), 24, C_ACCENT)
	var stage_col := C_MULT if game.stage() == 2 else C_TEXT
	_pill(Rect2(W - 272, 22, 140, 32), "Ante %d · %s" % [game.ante(), Game.STAGE_NAMES[game.stage()]], stage_col)
	_pill(Rect2(W - 124, 22, 100, 32), "$%d" % game.money, C_ACCENT)


func _draw_score_panel() -> void:
	var r := Rect2(24, 68, W - 48, 96)
	_box(r, C_PANEL, 14, C_BORDER, 1)
	if game.stage() == 2 and game.boss != "":
		_text("BOSS: " + Game.BOSSES[game.boss].name.to_upper(), r.position + Vector2(16, 26), 12, C_MULT)
	else:
		_text("ROUND SCORE", r.position + Vector2(16, 26), 12, C_MUTED)
	_text(str(int(shown_score)), r.position + Vector2(16, 64), 36)
	_text("/ %d" % game.target, r.position + Vector2(0, 64), 18, C_MUTED, r.size.x - 16, HORIZONTAL_ALIGNMENT_RIGHT)
	# Turns as dots
	_text("TURNS", r.position + Vector2(r.size.x - 150, 26), 12, C_MUTED)
	for i in game.max_turns:
		var c := r.position + Vector2(r.size.x - 96 + i * 16, 21)
		draw_circle(c, 5, C_ACCENT if i < game.turns_left else C_BORDER)
	var bar := Rect2(r.position + Vector2(16, 78), Vector2(r.size.x - 32, 6))
	_box(bar, C_BORDER, 3)
	var frac := clampf(shown_score / maxf(game.target, 1), 0.0, 1.0)
	if frac > 0.0:
		_box(Rect2(bar.position, Vector2(maxf(bar.size.x * frac, 6), bar.size.y)), C_ACCENT, 3)


func _draw_chain_panel() -> void:
	var live := game.in_chain
	var chips := game.chain_chips if live else game.last_chips
	var mult := maxi(game.chain_mult, 0) if live else game.last_mult
	var y := 176.0
	var chip_r := Rect2(24, y, 120, 52)
	var mult_r := Rect2(176, y, 120, 52)
	_box(chip_r, C_CHIPS, 10)
	_box(mult_r, C_MULT, 10)
	_text(str(chips), chip_r.position + Vector2(0, 35), 26, C_TEXT, chip_r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_text(str(mult), mult_r.position + Vector2(0, 35), 26, C_TEXT, mult_r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_text("x", Vector2(144, y + 34), 22, C_MUTED, 32, HORIZONTAL_ALIGNMENT_CENTER)
	if live:
		var extra := "  x%s" % str(snappedf(game.chain_xmult, 0.1)) if game.chain_xmult != 1.0 else ""
		_text("chain" + extra, Vector2(304, y + 34), 18, C_MULT if extra != "" else C_MUTED, W - 328, HORIZONTAL_ALIGNMENT_RIGHT)
	elif game.last_gain > 0:
		_text("= %d" % game.last_gain, Vector2(304, y + 36), 26, C_ACCENT, W - 328, HORIZONTAL_ALIGNMENT_RIGHT)


func _draw_board() -> void:
	_box(Rect2(ORIGIN - Vector2(8, 8), Vector2(CELL * Board.SIZE + 16, CELL * Board.SIZE + 16)), C_PANEL, 14, C_BORDER, 1)
	var targets: Array = game.legal_targets(game.selected) if game.state == "play" else []
	for y in Board.SIZE:
		for x in Board.SIZE:
			var p := Vector2i(x, y)
			var r := Rect2(ORIGIN + Vector2(x, y) * CELL, Vector2(CELL, CELL))
			draw_rect(r, C_DARK if Board.is_dark(p) else C_LIGHT)
			var c := r.get_center()
			match game.board.get_tile(p):
				Board.Tile.GOLD:
					draw_rect(r.grow(-6), C_GOLD_TILE, false, 4)
				Board.Tile.RED:
					draw_rect(r.grow(-6), C_RED_TILE, false, 4)
			if game.bot_last_move.has(p):
				draw_rect(r, C_BOT)
			if p == game.selected:
				draw_rect(r, C_HILITE)
			if targets.has(p):
				draw_circle(c, 10, C_HILITE)
			var v: int = game.board.get_cell(p)
			if v == Board.EMPTY:
				continue
			var col := C_PLAYER if Board.is_player(v) else C_FOE
			draw_circle(c, CELL * 0.36, col.darkened(0.35))
			draw_circle(c, CELL * 0.30, col)
			if v == Board.KING or v == Board.FOE_KING:
				draw_circle(c, CELL * 0.14, C_GOLD_TILE)


func _draw_card(rect: Rect2, id: String, selected := false, lift := 0.0) -> void:
	var info: Dictionary = Cards.ALL[id]
	var rc: Color = RARITY_COLORS[info.rarity]
	rect.position.y -= lift
	_box(rect, C_PANEL_HI, 10, rc if selected else C_BORDER, 2 if selected else 1)
	_box(Rect2(rect.position + Vector2(6, 6), Vector2(rect.size.x - 12, 4)), rc, 2)
	_text(TAGS.get(id, ""), rect.position + Vector2(0, 26), 10, rc, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_wrap(info.name, rect.position + Vector2(6, 46), rect.size.x - 12, 13, C_TEXT, 3, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_card_row(origin: Vector2, interactive: bool) -> void:
	_text("CARDS  %d/%d" % [game.cards.size(), Cards.SLOTS], origin + Vector2(0, -6), 11, C_MUTED)
	_text("trigger left to right", origin + Vector2(0, -6), 11, C_MUTED, W - 48, HORIZONTAL_ALIGNMENT_RIGHT)
	for i in Cards.SLOTS:
		var r := Rect2(origin + Vector2(i * (CARD_SIZE.x + CARD_GAP), 4), CARD_SIZE)
		if i >= game.cards.size():
			_box(r, Color.TRANSPARENT, 10, C_BORDER, 1)
			continue
		var lift: float = 6.0 * (pulses.get(i, 0.0) / 0.35)
		_draw_card(r, game.cards[i].id, i == sel_card, lift)
		if interactive:
			var idx := i
			buttons.append([r, func(): sel_card = -1 if sel_card == idx else idx])
	for f in floaters:
		if f.slot >= game.cards.size():
			continue
		var x: float = origin.x + f.slot * (CARD_SIZE.x + CARD_GAP)
		var a: float = clampf(1.2 - f.t, 0.0, 1.0)
		var y: float = origin.y - 4 - f.t * 36
		_box(Rect2(x - 4, y - 18, CARD_SIZE.x + 8, 24), Color(C_BG, 0.85 * a), 8)
		_text(f.text, Vector2(x - 4, y), 13, Color(C_ACCENT, a), CARD_SIZE.x + 8, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_detail_bar(r: Rect2) -> void:
	if sel_card < 0 or sel_card >= game.cards.size():
		sel_card = -1
		var hint := "Tap a card to inspect, reorder or sell it."
		if game.state == "play" and game.stage() == 2 and game.boss != "":
			hint = "Boss rule: " + Game.BOSSES[game.boss].desc
		if game.state == "play" and game.message != "" and not game.message.begins_with("+"):
			hint = game.message
		_text(hint, r.position + Vector2(0, 25), 14, C_MUTED, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		return
	var card: Dictionary = game.cards[sel_card]
	var info: Dictionary = Cards.ALL[card.id]
	_box(r, C_PANEL, 10, C_BORDER, 1)
	_wrap(info.desc, r.position + Vector2(12, 17), r.size.x - 190, 13, C_TEXT, 2)
	var slot := sel_card
	_button(Rect2(r.end.x - 170, r.position.y + 4, 56, r.size.y - 8), "<", func():
		if game.move_left(slot):
			sel_card = slot - 1, slot > 0)
	_button(Rect2(r.end.x - 108, r.position.y + 4, 104, r.size.y - 8), "Sell $%d" % game.sell_value(slot), func():
		game.sell(slot)
		sel_card = -1)


func _draw_shop() -> void:
	_text("SHOP", Vector2(24, 50), 28, C_ACCENT)
	_pill(Rect2(W - 124, 22, 100, 32), "$%d" % game.money, C_ACCENT)
	_text(game.message, Vector2(24, 80), 15, C_MUTED)
	var card_w := (W - 48 - 2 * 12) / 3.0
	_text("CARDS", Vector2(24, 112), 11, C_MUTED)
	_text("TRAINING", Vector2(24, 382), 11, C_MUTED)
	var ci := 0
	var ti := 0
	for i in game.shop.size():
		var item: Dictionary = game.shop[i]
		var info: Dictionary = game.item_info(item)
		var idx := i
		if item.kind == "card":
			var r := Rect2(24 + ci * (card_w + 12), 120, card_w, 238)
			var rc: Color = RARITY_COLORS[info.rarity]
			_box(r, C_PANEL_HI, 12, C_BORDER, 1)
			_box(Rect2(r.position + Vector2(8, 8), Vector2(r.size.x - 16, 4)), rc, 2)
			_text(RARITY_NAMES[info.rarity].to_upper() + "  ·  " + TAGS.get(item.id, ""), r.position + Vector2(0, 32), 10, rc, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
			_wrap(info.name, r.position + Vector2(8, 56), r.size.x - 16, 16, C_TEXT, 2, HORIZONTAL_ALIGNMENT_CENTER)
			_wrap(info.desc, r.position + Vector2(10, 104), r.size.x - 20, 13, C_MUTED, 5, HORIZONTAL_ALIGNMENT_CENTER)
			_button(Rect2(r.position.x + 8, r.end.y - 48, r.size.x - 16, 40), "$%d" % game.item_cost(item), func(): game.buy(idx), game.can_buy(i), true)
			ci += 1
		else:
			var tw := (W - 48 - 12) / 2.0
			var r := Rect2(24 + ti * (tw + 12), 390, tw, 112)
			_box(r, C_PANEL_HI, 12, C_BORDER, 1)
			_text(info.name, r.position + Vector2(12, 26), 16)
			_text(info.desc, r.position + Vector2(12, 48), 13, C_MUTED)
			_button(Rect2(r.position.x + 10, r.end.y - 50, r.size.x - 20, 40), "$%d" % game.item_cost(item), func(): game.buy(idx), game.can_buy(i), true)
			ti += 1
	if ci == 0:
		_text("Sold out", Vector2(24, 240), 16, C_MUTED, W - 48, HORIZONTAL_ALIGNMENT_CENTER)
	var pl: Dictionary = game.levels.pawn
	var kl: Dictionary = game.levels.king
	_text("Pawn  +%d chips  +%d mult  +$%d" % [pl.chips, pl.mult, pl.coins], Vector2(24, 524), 13, C_MUTED)
	_text("King  +%d chips  +%d mult  +$%d" % [kl.chips, kl.mult, kl.coins], Vector2(24, 542), 13, C_MUTED)
	_draw_card_row(Vector2(24, 600), true)
	_draw_detail_bar(Rect2(24, 716, W - 48, 38))
	_button(Rect2(24, 784, 160, 52), "Reroll $%d" % Game.REROLL_COST, func(): game.reroll(), game.money >= Game.REROLL_COST)
	var next_r: int = game.round_num + 1
	var next_label := "Next: %s round" % Game.STAGE_NAMES[Game.stage_of(next_r)]
	if Game.stage_of(next_r) == 2 and game.boss != "":
		_text("Next boss: %s. %s" % [Game.BOSSES[game.boss].name, Game.BOSSES[game.boss].desc], Vector2(24, 774), 13, C_MULT, W - 48, HORIZONTAL_ALIGNMENT_CENTER)
		next_label = "Next: Boss round"
	_button(Rect2(196, 784, W - 220, 52), next_label, func():
		sel_card = -1
		game.next_round()
		shown_score = 0.0, true, true)


func _draw_lost() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(C_BG, 0.8))
	var r := Rect2(48, 300, W - 96, 220)
	_box(r, C_PANEL, 16, C_BORDER, 1)
	_text("Run over", r.position + Vector2(0, 56), 30, C_TEXT, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_text(game.message, r.position + Vector2(0, 92), 15, C_MUTED, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_text("You reached round %d" % game.round_num, r.position + Vector2(0, 118), 15, C_MUTED, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_button(Rect2(r.position.x + 40, r.end.y - 72, r.size.x - 80, 52), "New run", func():
		sel_card = -1
		game.new_run()
		shown_score = 0.0, true, true)


func _draw_won() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(C_BG, 0.85))
	var r := Rect2(48, 280, W - 96, 280)
	_box(r, C_PANEL, 16, C_ACCENT, 2)
	_text("Victory!", r.position + Vector2(0, 60), 34, C_ACCENT, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_text(game.message, r.position + Vector2(0, 96), 15, C_MUTED, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_button(Rect2(r.position.x + 40, r.end.y - 136, r.size.x - 80, 52), "Keep going (endless)", func(): game.continue_endless(), true, true)
	_button(Rect2(r.position.x + 40, r.end.y - 72, r.size.x - 80, 52), "New run", func():
		sel_card = -1
		game.new_run()
		shown_score = 0.0)
