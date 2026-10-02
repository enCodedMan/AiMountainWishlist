extends Node2D
## Game UI: everything is drawn with _draw and hit-tested by hand.

const Game = preload("res://scripts/game.gd")
const Board = preload("res://scripts/board.gd")
const Relics = preload("res://scripts/relics.gd")
const Formations = preload("res://scripts/formations.gd")
const Sfx = preload("res://scripts/sfx.gd")
const Profile = preload("res://scripts/profile.gd")
const Steam = preload("res://scripts/steam.gd")

const W := 480.0
const H := 860.0
const CELL := 72.0
const ORIGIN := Vector2(24, 244)
const CARD_SIZE := Vector2(80, 100)
const CARD_GAP := 8.0
const STEP_TIME := 0.13
const BOT_DELAY := 0.22
const ZAP_TIME := 0.3

# Board colours
const C_LIGHT := Color("e9d8b4")
const C_DARK := Color("8a5a3c")
const C_PLAYER := Color("f4f1ea")
const C_FOE := Color("c0392b")
const C_CROWN := Color("f1c40f")
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
const C_DANGER := Color("ef4444")
const C_GOOD := Color("4ade80")
const RARITY_COLORS := [Color("94a3b8"), Color("2dd4bf"), Color("a78bfa")]
const RARITY_NAMES := ["Common", "Uncommon", "Rare"]

var game := Game.new()
var font: Font
var buttons: Array = []  # [Rect2, Callable]
var sel_relic := -1  # selected owned relic slot, for the detail bar
var pulses := {}  # slot -> remaining seconds
var floaters: Array = []  # [{"slot", "text", "t"}], t < 0 means not shown yet
var last_state := ""
var sfx: Node
## Queued animations from game events; only the head advances.
var anims: Array = []
var shake := 0.0
var popups: Array = []  # [{"text", "t", "color"}]
var jump_streak := 0  # rising pitch within a chain
var profile := Profile.new()
var screen := "title"  # title | collection | game
var run_recorded := false
var toasts: Array = []  # [{"text", "t"}]
var coll_sel := ""


func _ready() -> void:
	font = ThemeDB.fallback_font
	sfx = Sfx.new()
	add_child(sfx)
	profile.load_profile()
	get_tree().set_quit_on_go_back(false)
	Steam.start()
	_fit_safe_area()
	game.unlocked = profile.data.unlocked.duplicate()
	game.new_run()
	game.take_events()


## Keep the layout clear of notches and rounded corners on phones.
func _fit_safe_area() -> void:
	if not OS.has_feature("mobile"):
		return
	var win := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if win.y <= 0:
		return
	var top := float(safe.position.y) / win.y * H
	var bottom := float(win.y - safe.end.y) / win.y * H
	var k := (H - top - bottom) / H
	scale = Vector2(k, k)
	position = Vector2(W * (1.0 - k) / 2.0, top)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if screen == "game":
			_to_title()
		elif screen == "collection":
			screen = "title"
		queue_redraw()
	elif what == NOTIFICATION_WM_SIZE_CHANGED:
		_fit_safe_area()


func _start_run() -> void:
	game.unlocked = profile.data.unlocked.duplicate()
	game.army_id = profile.data.army if Game.ARMIES.has(profile.data.army) else "classic"
	game.new_run()
	anims.clear()
	popups.clear()
	floaters.clear()
	sel_relic = -1
	run_recorded = false
	screen = "game"
	queue_redraw()


func _play(id: String, pitch := 1.0) -> void:
	if profile.data.sfx:
		sfx.play(id, pitch)


func _shake(amount: float) -> void:
	if profile.data.shake:
		shake = maxf(shake, amount)


## The state the screen shows: the game may already be in the shop while the last move animates.
func view_state() -> String:
	return game.state if anims.is_empty() else "play"


func _process(delta: float) -> void:
	var evs := game.take_events()
	if not evs.is_empty():
		for id in profile.check_unlocks(game):
			Steam.achieve(id)
			if id.begins_with("army:"):
				toasts.append({"text": "New army unlocked: " + Game.ARMIES[id.substr(5)].name, "t": 0.0})
			else:
				toasts.append({"text": "New relic unlocked: " + Relics.ALL[id].name, "t": 0.0})
	if (game.state == "lost" or game.state == "won") and not run_recorded and screen == "game":
		run_recorded = true
		profile.end_run(game, game.state == "won")
		if game.state == "won":
			Steam.achieve("win")
	for t in toasts:
		t.t += delta
	toasts = toasts.filter(func(t): return t.t < 3.0)
	for e in evs:
		var dur := 0.0
		match e.type:
			"move":
				dur = STEP_TIME * (e.path.size() - 1) + (BOT_DELAY if e.by == "bot" else 0.0)
			"zap":
				dur = ZAP_TIME
			"gold":
				dur = 0.45
			"win", "lost":
				dur = 0.6
		anims.append(e.merged({"t": 0.0, "dur": dur, "started": false}))
	var fx := game.take_fx()
	for i in fx.size():
		floaters.append({"slot": fx[i].slot, "text": fx[i].text, "t": -0.09 * i})
	_advance_anims(delta)
	var busy := not pulses.is_empty() or not floaters.is_empty() or not anims.is_empty() \
		or shake > 0.0 or not popups.is_empty() or not toasts.is_empty()
	for k in pulses.keys():
		pulses[k] -= delta
		if pulses[k] <= 0.0:
			pulses.erase(k)
	for f in floaters:
		var was_hidden: bool = f.t < 0.0
		f.t += delta
		if was_hidden and f.t >= 0.0:
			pulses[f.slot] = 0.35
			_play("tick", 1.0 + 0.08 * f.slot)
	floaters = floaters.filter(func(f): return f.t < 1.1)
	for p in popups:
		p.t += delta
	popups = popups.filter(func(p): return p.t < 1.0)
	shake = maxf(shake - delta * 30.0, 0.0)
	if busy:
		queue_redraw()


func _advance_anims(delta: float) -> void:
	while not anims.is_empty():
		var a: Dictionary = anims[0]
		if not a.started:
			a.started = true
			_on_anim_start(a)
		a.t += delta
		if a.t < a.dur:
			return
		delta = a.t - a.dur
		anims.pop_front()
		_on_anim_end(a)


func _on_anim_start(a: Dictionary) -> void:
	match a.type:
		"gold":
			popups.append({"text": "+$%d" % a.amount, "t": 0.0, "color": C_ACCENT})
			_play("coin")
		"zap":
			_play("hit", 1.3)
			_shake(7.0)
		"win":
			popups.append({"text": "Round won!", "t": 0.0, "color": C_GOOD})
			_play("win")
		"lost":
			popups.append({"text": "Round lost", "t": 0.0, "color": C_DANGER})
			_play("lose")
			_shake(8.0)


func _on_anim_end(a: Dictionary) -> void:
	if a.type != "move":
		return
	if a.captured.is_empty():
		_play("step")
		if a.by == "player":
			jump_streak = 0
	elif a.by == "bot":
		_play("hit")
		_shake(6.0)
	else:
		jump_streak += 1
		_play("jump", 1.0 + 0.12 * (jump_streak - 1))


## Where a moving piece is drawn right now.
func _anim_pos(a: Dictionary) -> Vector2:
	var path: Array = a.path
	var t: float = a.t - (BOT_DELAY if a.by == "bot" else 0.0)
	if not a.started or t <= 0.0:
		return ORIGIN + (Vector2(path[0]) + Vector2(0.5, 0.5)) * CELL
	var seg := clampf(t / STEP_TIME, 0.0, path.size() - 1.0)
	var i := mini(int(seg), path.size() - 2)
	var k := ease(seg - i, -2.0)
	var p := Vector2(path[i]).lerp(Vector2(path[i + 1]), k)
	var hop := sin(k * PI) * (10.0 if not a.captured.is_empty() else 3.0)
	return ORIGIN + (p + Vector2(0.5, 0.5)) * CELL - Vector2(0, hop)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not anims.is_empty():
		return
	var pos := get_local_mouse_position()
	for i in range(buttons.size() - 1, -1, -1):
		if buttons[i][0].has_point(pos):
			buttons[i][1].call()
			_play("select")
			queue_redraw()
			return
	if screen == "game" and game.state == "play":
		var cell := Vector2i(((pos - ORIGIN) / CELL).floor())
		if game.tap(cell):
			if game.board.in_bounds(cell) and game.selected == cell:
				_play("select")
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
	_text(label, rect.position + Vector2(0, rect.size.y / 2 + 6), 16, fg, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	if enabled:
		buttons.append([rect, action])


func _pill(rect: Rect2, label: String, color := C_TEXT) -> void:
	_box(rect, C_PANEL, int(rect.size.y / 2), C_BORDER, 1)
	_text(label, rect.position + Vector2(0, rect.size.y / 2 + 6), 15, color, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_piece(c: Vector2, v: int, alpha := 1.0, radius := CELL * 0.36) -> void:
	var col := C_PLAYER if Board.is_player(v) else C_FOE
	var r := radius if alpha >= 1.0 else radius * (0.6 + 0.4 * alpha)
	draw_circle(c, r, Color(col.darkened(0.35), alpha))
	draw_circle(c, r * 0.83, Color(col, alpha))
	if Board.is_king(v):
		draw_circle(c, r * 0.39, Color(C_CROWN, alpha))


func _heart(c: Vector2, size: float, color: Color) -> void:
	var s := size / 2.0
	draw_circle(c + Vector2(-s * 0.5, -s * 0.2), s * 0.55, color)
	draw_circle(c + Vector2(s * 0.5, -s * 0.2), s * 0.55, color)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 1.02, 0), c + Vector2(s * 1.02, 0), c + Vector2(0, s * 1.1)]), color)


# --- Screens -------------------------------------------------------------------

func _draw() -> void:
	buttons.clear()
	var st := view_state()
	if st != last_state:
		last_state = st
		floaters.clear()
		pulses.clear()
	draw_rect(Rect2(0, 0, W, H), C_BG)
	if screen == "title":
		_draw_title()
		_draw_toasts()
		return
	if screen == "collection":
		_draw_collection()
		return
	if st == "shop":
		_draw_shop()
		_draw_toasts()
		return
	if shake > 0.0:
		draw_set_transform(Vector2(randf_range(-shake, shake), randf_range(-shake, shake)) * 0.5)
	_draw_top_bar()
	_draw_objective()
	_draw_message()
	_draw_board()
	_draw_relic_row(Vector2(24, 708), true)
	_draw_detail_bar(Rect2(24, 816, W - 48, 38))
	_draw_popups()
	draw_set_transform(Vector2.ZERO)
	if st == "lost":
		_draw_lost()
	elif st == "won":
		_draw_won()
	_draw_toasts()


func _draw_top_bar() -> void:
	_button(Rect2(24, 22, 72, 32), "Menu", func(): _to_title())
	var stage_col := C_DANGER if game.stage() == 2 else C_TEXT
	_pill(Rect2(W - 272, 22, 140, 32), "Ante %d · %s" % [game.ante(), Game.STAGE_NAMES[game.stage()]], stage_col)
	_pill(Rect2(W - 124, 22, 100, 32), "$%d" % game.money, C_ACCENT)


func _draw_objective() -> void:
	var r := Rect2(24, 68, W - 48, 96)
	_box(r, C_PANEL, 14, C_BORDER, 1)
	var eyebrow: String = game.formation.name.to_upper()
	if game.stage() == 2:
		eyebrow = "BOSS · %s · %s" % [Game.BOSSES[game.boss].name.to_upper(), eyebrow]
	_text(eyebrow, r.position + Vector2(16, 24), 12, C_DANGER if game.stage() == 2 else C_MUTED)
	var foes := game.board.count_side(-1)
	_text(str(foes), r.position + Vector2(16, 64), 36)
	_text("enemies left", r.position + Vector2(24 + 22 * str(foes).length(), 64), 15, C_MUTED)
	# Turns and lives on the right
	_text("TURNS", r.position + Vector2(r.size.x - 132, 24), 12, C_MUTED)
	_text("%d / %d" % [game.turns_left, game.max_turns], r.position + Vector2(r.size.x - 132, 50), 20,
		C_DANGER if game.turns_left <= 3 else C_TEXT)
	_text("LIVES", r.position + Vector2(r.size.x - 60, 24), 12, C_MUTED)
	for i in Game.ARMIES[game.army_id].hearts:
		_heart(r.position + Vector2(r.size.x - 52 + i * 16, 42), 12, C_DANGER if i < game.hearts else C_BORDER)
	var army_n := game.board.count_side(1)
	_text("Army %d" % army_n, r.position + Vector2(r.size.x - 132, 80), 14, C_MUTED)


func _draw_message() -> void:
	var r := Rect2(24, 176, W - 48, 52)
	var msg := game.message
	var col := C_TEXT
	if game.state == "play" and anims.is_empty():
		if game.in_chain:
			msg = "Keep jumping!"
			col = C_ACCENT
		elif msg == "" or msg == "Capture every enemy piece":
			if game.must_capture():
				msg = "Capture is mandatory. Glowing pieces must jump."
				col = C_ACCENT
			else:
				msg = "Your move. Capture every enemy piece."
	elif not anims.is_empty():
		msg = ""
	if msg.begins_with("The bot took"):
		col = C_DANGER
	_box(r, C_PANEL, 12)
	_wrap(msg, r.position + Vector2(14, 22), r.size.x - 28, 15, col, 2)


func _draw_board() -> void:
	_box(Rect2(ORIGIN - Vector2(8, 8), Vector2(CELL * Board.SIZE + 16, CELL * Board.SIZE + 16)), C_PANEL, 14, C_BORDER, 1)
	var idle := anims.is_empty() and game.state == "play"
	var targets: Array = game.legal_targets(game.selected) if idle else []
	var movable: Array = game.movable_pieces() if idle else []
	var forced := idle and (game.in_chain or game.must_capture())
	var hidden := {}  # cells whose piece is drawn by a pending animation instead
	for a in anims:
		if a.type == "move":
			hidden[a.path.back()] = true
	for y in Board.SIZE:
		for x in Board.SIZE:
			var p := Vector2i(x, y)
			var r := Rect2(ORIGIN + Vector2(x, y) * CELL, Vector2(CELL, CELL))
			draw_rect(r, C_DARK if Board.is_dark(p) else C_LIGHT)
			var c := r.get_center()
			if p == game.selected and idle:
				draw_rect(r, C_HILITE)
			if targets.has(p):
				draw_circle(c, 10, C_HILITE)
			var v: int = game.board.get_cell(p)
			if v != Board.EMPTY and not hidden.has(p):
				if forced and movable.has(p) and p != game.selected:
					draw_circle(c, CELL * 0.44, Color(C_ACCENT, 0.85))
				_draw_piece(c, v)
	# Pieces captured or destroyed by events that haven't played yet.
	for a in anims:
		if a.type == "move":
			for j in a.captured.size():
				var cap: Vector2i = a.captured[j]
				var fade := 1.0
				if a.started:
					var t: float = a.t - (BOT_DELAY if a.by == "bot" else 0.0)
					fade = clampf(1.0 - (t - STEP_TIME * (j + 0.5)) / 0.12, 0.0, 1.0)
				if fade > 0.0 and not hidden.has(cap):
					_draw_piece(ORIGIN + (Vector2(cap) + Vector2(0.5, 0.5)) * CELL, a.ctypes[j], fade)
		elif a.type == "zap":
			var f: float = 1.0 - (a.t / ZAP_TIME if a.started else 0.0)
			for j in a.cells.size():
				var c2 := ORIGIN + (Vector2(a.cells[j]) + Vector2(0.5, 0.5)) * CELL
				if a.started:
					draw_circle(c2, CELL * 0.5 * (1.0 - f) + 8, Color(C_ACCENT, f * 0.7))
				_draw_piece(c2, a.ctypes[j], clampf(f, 0.0, 1.0))
	for a in anims:
		if a.type == "move":
			_draw_piece(_anim_pos(a), a.piece)


func _draw_popups() -> void:
	for p in popups:
		var k: float = p.t
		var a := clampf(1.6 - k * 1.6, 0.0, 1.0)
		var size := int(40 * (1.0 + 0.25 * maxf(0.0, 0.2 - k) / 0.2))
		var y := ORIGIN.y + CELL * Board.SIZE / 2 - k * 50
		_text(p.text, Vector2(ORIGIN.x + 3, y + 3), size, Color(0, 0, 0, a * 0.6), CELL * Board.SIZE, HORIZONTAL_ALIGNMENT_CENTER)
		_text(p.text, Vector2(ORIGIN.x, y), size, Color(p.color, a), CELL * Board.SIZE, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_relic(rect: Rect2, id: String, selected := false, lift := 0.0, disabled := false) -> void:
	var info: Dictionary = Relics.ALL[id]
	var rc: Color = RARITY_COLORS[info.rarity]
	rect.position.y -= lift
	_box(rect, C_PANEL_HI, 10, rc if selected else C_BORDER, 2 if selected else 1)
	_box(Rect2(rect.position + Vector2(6, 6), Vector2(rect.size.x - 12, 4)), rc, 2)
	_text(info.tag, rect.position + Vector2(0, 26), 10, rc, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_wrap(info.name, rect.position + Vector2(4, 46), rect.size.x - 8, 13 if info.name.length() <= 7 or " " in info.name else 11, C_TEXT, 3, HORIZONTAL_ALIGNMENT_CENTER)
	if disabled:
		_box(rect, Color(C_BG, 0.7), 10)
		_text("OFF", rect.position + Vector2(0, rect.size.y - 12), 11, C_DANGER, rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_relic_row(origin: Vector2, interactive: bool) -> void:
	_text("RELICS  %d/%d" % [game.relics.size(), Relics.SLOTS], origin + Vector2(0, -6), 11, C_MUTED)
	for i in Relics.SLOTS:
		var r := Rect2(origin + Vector2(i * (CARD_SIZE.x + CARD_GAP), 4), CARD_SIZE)
		if i >= game.relics.size():
			_box(r, Color.TRANSPARENT, 10, C_BORDER, 1)
			continue
		var lift: float = 6.0 * (pulses.get(i, 0.0) / 0.35)
		_draw_relic(r, game.relics[i], i == sel_relic, lift, game._relic_disabled(i))
		if interactive:
			var idx := i
			buttons.append([r, func(): sel_relic = -1 if sel_relic == idx else idx])
	for f in floaters:
		if f.slot < 0 or f.slot >= game.relics.size() or f.t < 0.0:
			continue
		var x: float = origin.x + f.slot * (CARD_SIZE.x + CARD_GAP)
		var a: float = clampf(1.2 - f.t, 0.0, 1.0)
		var y: float = origin.y - 4 - f.t * 36
		_box(Rect2(x - 4, y - 18, CARD_SIZE.x + 8, 24), Color(C_BG, 0.85 * a), 8)
		_text(f.text, Vector2(x - 4, y), 13, Color(C_ACCENT, a), CARD_SIZE.x + 8, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_detail_bar(r: Rect2) -> void:
	if sel_relic < 0 or sel_relic >= game.relics.size():
		sel_relic = -1
		_text("Tap a relic to read it. Relics bend the rules.", r.position + Vector2(0, 25), 14, C_MUTED, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		return
	var info: Dictionary = Relics.ALL[game.relics[sel_relic]]
	_box(r, C_PANEL, 10, C_BORDER, 1)
	var in_shop := game.state == "shop"
	_wrap(info.desc, r.position + Vector2(12, 16), r.size.x - (190 if in_shop else 24), 13, C_TEXT, 2)
	if not in_shop:
		return
	var slot := sel_relic
	_button(Rect2(r.end.x - 170, r.position.y + 4, 56, r.size.y - 8), "<", func():
		if game.move_left(slot):
			sel_relic = slot - 1, slot > 0)
	_button(Rect2(r.end.x - 108, r.position.y + 4, 104, r.size.y - 8), "Sell $%d" % game.sell_value(slot), func():
		game.sell(slot)
		sel_relic = -1)


## A small picture of the next enemy formation.
func _draw_formation_preview(origin: Vector2, cell: float) -> void:
	for y in Board.SIZE:
		for x in Board.SIZE:
			draw_rect(Rect2(origin + Vector2(x, y) * cell, Vector2(cell, cell)), C_DARK if (x + y) % 2 == 1 else C_LIGHT)
	for p in game.enemy_layout():
		var king: bool = p[2] == "k" or (game.boss == "crowned" and p[1] == 0)
		_draw_piece(origin + (Vector2(p[0], p[1]) + Vector2(0.5, 0.5)) * cell, Board.FOE_KING if king else Board.FOE, 1.0, cell * 0.38)
	var home: Array = game.army.duplicate()
	home.sort_custom(func(a, b): return a == Board.PAWN and b == Board.KING)
	for i in mini(home.size(), Game.HOME.size()):
		_draw_piece(origin + (Vector2(Game.HOME[i]) + Vector2(0.5, 0.5)) * cell, home[i], 1.0, cell * 0.38)


func _draw_shop() -> void:
	_text("SHOP", Vector2(24, 50), 28, C_ACCENT)
	_pill(Rect2(W - 124, 22, 100, 32), "$%d" % game.money, C_ACCENT)
	_wrap(game.message, Vector2(24, 74), W - 48, 14, C_GOOD if game.last_result == "won" else C_DANGER, 2)
	# Relics for sale
	var card_w := (W - 48 - 2 * 12) / 3.0
	_text("RELICS", Vector2(24, 112), 11, C_MUTED)
	for i in game.shop.size():
		var id: String = game.shop[i]
		var info: Dictionary = Relics.ALL[id]
		var r := Rect2(24 + i * (card_w + 12), 120, card_w, 226)
		var rc: Color = RARITY_COLORS[info.rarity]
		_box(r, C_PANEL_HI, 12, C_BORDER, 1)
		_box(Rect2(r.position + Vector2(8, 8), Vector2(r.size.x - 16, 4)), rc, 2)
		_text(RARITY_NAMES[info.rarity].to_upper() + " · " + info.tag, r.position + Vector2(0, 30), 10, rc, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		_wrap(info.name, r.position + Vector2(8, 52), r.size.x - 16, 15, C_TEXT, 2, HORIZONTAL_ALIGNMENT_CENTER)
		_wrap(info.desc, r.position + Vector2(8, 94), r.size.x - 16, 12, C_MUTED, 5, HORIZONTAL_ALIGNMENT_CENTER)
		var idx := i
		_button(Rect2(r.position.x + 8, r.end.y - 46, r.size.x - 16, 38), "$%d" % game.relic_cost(id), func(): game.buy(idx), game.can_buy(i), true)
	if game.shop.is_empty():
		_text("Sold out", Vector2(24, 220), 16, C_MUTED, W - 48, HORIZONTAL_ALIGNMENT_CENTER)
	# Army services and next formation
	_text("YOUR ARMY", Vector2(24, 370), 11, C_MUTED)
	var pawns := game.army.count(Board.PAWN)
	var kings := game.army.count(Board.KING)
	_text("%d pawns, %d kings (max %d)" % [pawns, kings, Game.ARMY_MAX], Vector2(24, 392), 15)
	_button(Rect2(24, 404, 196, 40), "Recruit pawn $%d" % Game.RECRUIT_COST, func(): game.recruit(), game.can_recruit())
	_button(Rect2(24, 452, 196, 40), "Crown a pawn $%d" % Game.CROWN_COST, func(): game.crown_pawn(), game.can_crown())
	_button(Rect2(24, 500, 196, 40), "Reroll relics $%d" % Game.REROLL_COST, func(): game.reroll(), game.money >= Game.REROLL_COST)
	var pv := Vector2(248, 380)
	var label: String = "NEXT: " + game.formation.name.to_upper()
	if game.stage() == 2:
		label = "NEXT BOSS: " + Game.BOSSES[game.boss].name.to_upper()
	_text(label, Vector2(pv.x, 370), 11, C_DANGER if game.stage() == 2 else C_MUTED)
	_draw_formation_preview(pv + Vector2(0, 8), 24.0)
	if game.stage() == 2:
		_wrap("%s formation. %s" % [game.formation.name, Game.BOSSES[game.boss].desc], Vector2(pv.x, 548), W - 24 - pv.x, 12, C_DANGER, 2)
	_draw_relic_row(Vector2(24, 600), true)
	_draw_detail_bar(Rect2(24, 712, W - 48, 38))
	_button(Rect2(24, 784, W - 48, 52), "Next: %s round" % Game.STAGE_NAMES[game.stage()], func():
		sel_relic = -1
		game.next_round(), true, true)


func _draw_lost() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(C_BG, 0.8))
	var r := Rect2(48, 300, W - 96, 220)
	_box(r, C_PANEL, 16, C_BORDER, 1)
	_text("Run over", r.position + Vector2(0, 56), 30, C_TEXT, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_wrap(game.message, r.position + Vector2(16, 88), r.size.x - 32, 15, C_MUTED, 2, HORIZONTAL_ALIGNMENT_CENTER)
	_text("You reached ante %d" % game.ante(), r.position + Vector2(0, 136), 15, C_MUTED, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_button(Rect2(r.position.x + 40, r.end.y - 64, r.size.x / 2 - 46, 48), "Menu", func(): _to_title())
	_button(Rect2(r.position.x + r.size.x / 2 + 6, r.end.y - 64, r.size.x / 2 - 46, 48), "New run", func(): _start_run(), true, true)


func _draw_won() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(C_BG, 0.85))
	var r := Rect2(48, 280, W - 96, 280)
	_box(r, C_PANEL, 16, C_ACCENT, 2)
	_text("Victory!", r.position + Vector2(0, 60), 34, C_ACCENT, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_text(game.message, r.position + Vector2(0, 96), 15, C_MUTED, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_button(Rect2(r.position.x + 40, r.end.y - 136, r.size.x - 80, 52), "Keep going (endless)", func(): game.continue_endless(), true, true)
	_button(Rect2(r.position.x + 40, r.end.y - 72, r.size.x / 2 - 46, 52), "Menu", func(): _to_title())
	_button(Rect2(r.position.x + r.size.x / 2 + 6, r.end.y - 72, r.size.x / 2 - 46, 52), "New run", func(): _start_run())


# --- Menus -----------------------------------------------------------------------

func _to_title() -> void:
	if not run_recorded and game.state != "lost" and game.state != "won" and game.round_num > 1:
		profile.end_run(game, false)
	run_recorded = true
	screen = "title"


func _draw_toasts() -> void:
	for i in toasts.size():
		var t: Dictionary = toasts[i]
		var a := clampf(minf(t.t / 0.2, (3.0 - t.t) / 0.4), 0.0, 1.0)
		var r := Rect2(40, 64 + i * 52 - (1.0 - a) * 12, W - 80, 44)
		_box(r, Color(C_PANEL_HI, a), 12, Color(C_ACCENT, a), 2)
		_text(t.text, r.position + Vector2(0, 28), 15, Color(C_ACCENT, a), r.size.x, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_title() -> void:
	var crest := Vector2(W / 2 - 96, 70)
	for y in 4:
		for x in 4:
			draw_rect(Rect2(crest + Vector2(x, y) * 48, Vector2(48, 48)), C_DARK if (x + y) % 2 == 1 else C_LIGHT)
	_draw_piece(crest + Vector2(1.5, 0.5) * 48, Board.FOE, 1.0, 48 * 0.36)
	_draw_piece(crest + Vector2(3.5, 2.5) * 48, Board.FOE, 1.0, 48 * 0.36)
	_draw_piece(crest + Vector2(0.5, 3.5) * 48, Board.KING, 1.0, 48 * 0.36)
	_text("KINGJUMP", Vector2(0, 336), 56, C_ACCENT, W, HORIZONTAL_ALIGNMENT_CENTER)
	_text("Beat the bot at checkers. Bend the rules.", Vector2(0, 370), 16, C_MUTED, W, HORIZONTAL_ALIGNMENT_CENTER)
	var d0: Dictionary = profile.data
	var owned: Array = Game.ARMIES.keys().filter(func(k): return d0.armies.has(k))
	var cur: String = d0.army if owned.has(d0.army) else "classic"
	var army_r := Rect2(80, 444, W - 160, 60)
	_box(army_r, C_PANEL, 12, C_BORDER, 1)
	_text("ARMY: " + Game.ARMIES[cur].name.to_upper(), army_r.position + Vector2(0, 26), 14, C_ACCENT, army_r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_text(Game.ARMIES[cur].desc, army_r.position + Vector2(0, 47), 13, C_MUTED, army_r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	if owned.size() > 1:
		var step := func(dirn: int):
			d0.army = owned[(owned.find(cur) + dirn + owned.size()) % owned.size()]
			profile.save_profile()
		_button(Rect2(army_r.position.x + 6, army_r.position.y + 10, 36, 40), "<", func(): step.call(-1))
		_button(Rect2(army_r.end.x - 42, army_r.position.y + 10, 36, 40), ">", func(): step.call(1))
	_text("%d/%d armies" % [owned.size(), Game.ARMIES.size()], Vector2(0, 522), 12, C_MUTED, W, HORIZONTAL_ALIGNMENT_CENTER)
	_button(Rect2(80, 536, W - 160, 56), "Play", func(): _start_run(), true, true)
	_button(Rect2(80, 604, W - 160, 52), "Relics", func():
		coll_sel = ""
		screen = "collection")
	var d: Dictionary = profile.data
	_button(Rect2(80, 668, (W - 172) / 2, 48), "Sound: %s" % ("On" if d.sfx else "Off"), func():
		d.sfx = not d.sfx
		profile.save_profile())
	_button(Rect2(92 + (W - 172) / 2, 668, (W - 172) / 2, 48), "Shake: %s" % ("On" if d.shake else "Off"), func():
		d.shake = not d.shake
		profile.save_profile())
	_text("Runs %d  ·  Wins %d  ·  Best ante %d  ·  Relics %d/%d" % [d.runs, d.wins, d.best_ante, d.unlocked.size(), Relics.ALL.size()],
		Vector2(0, 760), 14, C_MUTED, W, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_collection() -> void:
	_text("Relics", Vector2(24, 50), 28, C_ACCENT)
	_text("%d / %d unlocked" % [profile.data.unlocked.size(), Relics.ALL.size()], Vector2(24, 50), 15, C_MUTED, W - 48, HORIZONTAL_ALIGNMENT_RIGHT)
	var cw := (W - 48 - 4 * 8) / 5.0
	var ids := Relics.ALL.keys()
	for i in ids.size():
		var id: String = ids[i]
		var r := Rect2(24 + (i % 5) * (cw + 8), 76 + (i / 5) * 104, cw, 96)
		if profile.is_unlocked(id):
			_draw_relic(r, id, coll_sel == id)
		else:
			_box(r, C_PANEL, 10, C_ACCENT if coll_sel == id else C_BORDER, 2 if coll_sel == id else 1)
			_text("?", r.position + Vector2(0, 58), 26, C_MUTED, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		buttons.append([r, func(): coll_sel = id])
	var info_r := Rect2(24, 704, W - 48, 80)
	_box(info_r, C_PANEL, 12, C_BORDER, 1)
	if coll_sel == "":
		_text("Tap a relic to see what it does.", info_r.position + Vector2(0, 38), 14, C_MUTED, info_r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	elif profile.is_unlocked(coll_sel):
		var info: Dictionary = Relics.ALL[coll_sel]
		_text("%s  ·  %s" % [info.name, RARITY_NAMES[info.rarity]], info_r.position + Vector2(14, 24), 15, RARITY_COLORS[info.rarity])
		_wrap(info.desc, info_r.position + Vector2(14, 44), info_r.size.x - 28, 13, C_TEXT, 2)
	else:
		_text("Locked", info_r.position + Vector2(14, 24), 15, C_MUTED)
		_text("Unlock: " + Profile.UNLOCK_HINTS.get(coll_sel, ""), info_r.position + Vector2(14, 48), 13, C_TEXT)
	_button(Rect2(24, 794, W - 48, 52), "Back", func(): screen = "title")
