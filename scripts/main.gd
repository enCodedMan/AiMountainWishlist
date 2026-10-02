extends Node2D
## Prototype UI: everything is drawn with _draw and hit-tested by hand.

const Game = preload("res://scripts/game.gd")
const Board = preload("res://scripts/board.gd")
const Relics = preload("res://scripts/relics.gd")
const Content = preload("res://scripts/content.gd")

const CELL := 72.0
const ORIGIN := Vector2(24, 190)
const W := 480.0

const C_BG := Color("1d1b2a")
const C_LIGHT := Color("e9d8b4")
const C_DARK := Color("8a5a3c")
const C_PLAYER := Color("f4f1ea")
const C_FOE := Color("c0392b")
const C_GOLD := Color("f1c40f")
const C_RED := Color("e74c3c")
const C_HILITE := Color(0.3, 0.9, 0.5, 0.55)
const C_TEXT := Color("f4f1ea")
const C_BTN := Color("3d3a5c")
const C_CARD := Color("2e6b8a")
const C_BOT := Color(1.0, 0.4, 0.3, 0.35)

var game := Game.new()
var font: Font
var buttons: Array = []  # [Rect2, Callable]


func _ready() -> void:
	font = ThemeDB.fallback_font
	game.new_run()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var pos := get_local_mouse_position()
	for b in buttons:
		if b[0].has_point(pos):
			b[1].call()
			queue_redraw()
			return
	if game.state == "play":
		var cell := Vector2i(((pos - ORIGIN) / CELL).floor())
		if game.tap(cell):
			queue_redraw()


func _draw() -> void:
	buttons.clear()
	draw_rect(Rect2(0, 0, W, 860), C_BG)
	_draw_hud()
	_draw_board()
	_draw_relics()
	if game.state == "shop":
		_draw_shop()
	elif game.state == "lost":
		_draw_lost()


func _text(s: String, pos: Vector2, size := 20, color := C_TEXT, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(font, pos, s, align, width, size, color)


func _button(rect: Rect2, label: String, action: Callable, enabled := true) -> void:
	draw_rect(rect, C_BTN if enabled else C_BTN.darkened(0.5))
	_text(label, rect.position + Vector2(0, rect.size.y / 2 + 7), 20, C_TEXT if enabled else Color(1, 1, 1, 0.4), rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	if enabled:
		buttons.append([rect, action])


func _draw_hud() -> void:
	_text("KINGJUMP", Vector2(24, 44), 30, C_GOLD)
	_text("Round %d" % game.round_num, Vector2(24, 80), 22)
	_text("$%d" % game.money, Vector2(W - 124, 80), 22, C_GOLD, 100, HORIZONTAL_ALIGNMENT_RIGHT)
	_text("Score %d / %d" % [game.score, game.target], Vector2(24, 112), 24)
	_text("Turns %d" % game.turns_left, Vector2(W - 124, 112), 22, C_TEXT, 100, HORIZONTAL_ALIGNMENT_RIGHT)
	if game.in_chain:
		_text("Chain: %d chips x %d mult" % [game.chain_chips, game.chain_mult], Vector2(24, 150), 20, C_GOLD)
	else:
		_text(game.message, Vector2(24, 150), 18)


func _draw_board() -> void:
	var targets: Array = game.legal_targets(game.selected) if game.state == "play" else []
	for y in Board.SIZE:
		for x in Board.SIZE:
			var p := Vector2i(x, y)
			var r := Rect2(ORIGIN + Vector2(x, y) * CELL, Vector2(CELL, CELL))
			draw_rect(r, C_DARK if Board.is_dark(p) else C_LIGHT)
			var c := r.get_center()
			match game.board.get_tile(p):
				Board.Tile.GOLD:
					draw_rect(r.grow(-6), C_GOLD, false, 4)
				Board.Tile.RED:
					draw_rect(r.grow(-6), C_RED, false, 4)
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
				draw_circle(c, CELL * 0.14, C_GOLD)


func _draw_relics() -> void:
	var y := ORIGIN.y + CELL * Board.SIZE + 16
	# Hand of booster cards: tap to use.
	_text("Cards (tap to use)%s" % ("  x2 mult ready!" if game.double_next else ""), Vector2(24, y + 16), 18, C_GOLD)
	var cw := (W - 48 - 16) / Content.HAND_SIZE
	for i in Content.HAND_SIZE:
		var r := Rect2(24 + i * (cw + 8), y + 26, cw, 64)
		if i < game.hand.size():
			var c: Dictionary = Content.CARDS[game.hand[i]]
			draw_rect(r, C_CARD)
			_text(c.name, r.position + Vector2(0, 22), 16, C_TEXT, cw, HORIZONTAL_ALIGNMENT_CENTER)
			draw_multiline_string(font, r.position + Vector2(4, 44), c.desc, HORIZONTAL_ALIGNMENT_CENTER, cw - 8, 11, 2)
			if game.state == "play":
				var idx := i
				buttons.append([r, func(): game.use_card(idx)])
		else:
			draw_rect(r, C_CARD.darkened(0.6), false, 2)
	y += 112
	var pl: Dictionary = game.levels.pawn
	var kl: Dictionary = game.levels.king
	_text("Pawn +%d chips +%d mult +$%d   King +%d chips +%d mult +$%d" % [pl.chips, pl.mult, pl.coins, kl.chips, kl.mult, kl.coins], Vector2(24, y), 14)
	y += 26
	_text("Relics", Vector2(24, y), 18, C_GOLD)
	if game.relics.is_empty():
		_text("none yet: clear a round to shop", Vector2(24, y + 22), 14)
	for i in game.relics.size():
		var rl: Dictionary = Relics.ALL[game.relics[i]]
		_text("%s: %s" % [rl.name, rl.desc], Vector2(24, y + 22 + i * 20), 14)


func _draw_shop() -> void:
	draw_rect(Rect2(8, 8, W - 16, 844), C_BG)
	_text("SHOP", Vector2(28, 52), 30, C_GOLD)
	_text("$%d" % game.money, Vector2(W - 140, 52), 26, C_GOLD, 112, HORIZONTAL_ALIGNMENT_RIGHT)
	_text(game.message, Vector2(28, 84), 18)
	var kinds := {"relic": "RELIC", "card": "CARD", "train": "TRAINING"}
	for i in game.shop.size():
		var item: Dictionary = game.shop[i]
		var info: Dictionary = game.item_info(item)
		var y := 104.0 + i * 92
		_text(kinds[item.kind], Vector2(28, y + 18), 12, C_GOLD)
		_text("%s ($%d)" % [info.name, game.item_cost(item)], Vector2(28, y + 40), 19)
		_text(info.desc, Vector2(28, y + 62), 14, C_TEXT, W - 180)
		var idx := i
		_button(Rect2(W - 130, y + 16, 100, 44), "Buy", func(): game.buy(idx), game.can_buy(i))
	_button(Rect2(28, 776, 190, 52), "Reroll ($%d)" % Game.REROLL_COST, func(): game.reroll(), game.money >= Game.REROLL_COST)
	_button(Rect2(W - 218, 776, 190, 52), "Next round", func(): game.next_round())


func _draw_lost() -> void:
	draw_rect(Rect2(16, 300, W - 32, 240), Color(0, 0, 0, 0.85))
	_text("RUN OVER", Vector2(16, 360), 32, C_RED, W - 32, HORIZONTAL_ALIGNMENT_CENTER)
	_text(game.message, Vector2(16, 400), 18, C_TEXT, W - 32, HORIZONTAL_ALIGNMENT_CENTER)
	_text("Reached round %d" % game.round_num, Vector2(16, 430), 18, C_TEXT, W - 32, HORIZONTAL_ALIGNMENT_CENTER)
	_button(Rect2(W / 2 - 100, 460, 200, 52), "New run", func(): game.new_run())
