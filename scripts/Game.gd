extends Control
## Цифры v2 — UI и правила как в веб-версии (меню / игра / лавка / баг / день-ночь).

const COLS := 9
const ADDS_PER_GAME := 5
const LOG_MAX := 80
const INITIAL := [
	[1, 2, 3, 4, 5, 6, 7, 8, 9],
	[1, 1, 1, 2, 1, 3, 1, 4, 1],
	[5, 1, 6, 1, 7, 1, 8, 1, 9],
]

var grid: Array = []
var selected: Vector2i = Vector2i(-1, -1)
var moves := 0
var coins := 80
var hints := 4
var adds_left := ADDS_PER_GAME
var extra_adds := 0
var ads_removed := false
var games_won := 0
var best_moves := -1
var history: Array = []
var is_day := false
var action_log: PackedStringArray = PackedStringArray()
var last_fail := ""
var hint_a := Vector2i(-1, -1)
var hint_b := Vector2i(-1, -1)
var screen := "menu"
var toast_text := ""

var ui: Dictionary = {}


func _ready() -> void:
	_load_meta()
	_build_ui()
	_show("menu")
	Ads.show_banner()


func _pal() -> Dictionary:
	if is_day:
		return {
			"bg": Color("f3efe6"),
			"surface": Color("e7e1d4"),
			"elevated": Color("fffdf8"),
			"cell": Color("fffdf8"),
			"fg": Color("1c1b18"),
			"muted": Color("5e5a52"),
			"accent": Color("1c1b18"),
			"accent_fg": Color("f3efe6"),
			"ok": Color("3d6a4c"),
			"bad": Color("b44538"),
		}
	return {
		"bg": Color("0c0d10"),
		"surface": Color("15171c"),
		"elevated": Color("1c1f26"),
		"cell": Color("23262e"),
		"fg": Color("f3efe6"),
		"muted": Color("9a958a"),
		"accent": Color("c8ccd4"),
		"accent_fg": Color("0c0d10"),
		"ok": Color("6f8f78"),
		"bad": Color("c45c4a"),
	}


func _round_style(color: Color, radius := 16) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	return s


func _pill(text: String, filled: bool) -> Button:
	var p: Dictionary = _pal()
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 16)
	if filled:
		b.add_theme_stylebox_override("normal", _round_style(p.accent, 18))
		b.add_theme_stylebox_override("hover", _round_style(p.accent, 18))
		b.add_theme_stylebox_override("pressed", _round_style(p.accent, 18))
		b.add_theme_color_override("font_color", p.accent_fg)
	else:
		var st := _round_style(p.surface, 18)
		st.border_width_left = 1
		st.border_width_top = 1
		st.border_width_right = 1
		st.border_width_bottom = 1
		st.border_color = Color(p.fg.r, p.fg.g, p.fg.b, 0.12)
		b.add_theme_stylebox_override("normal", st)
		b.add_theme_stylebox_override("hover", st)
		b.add_theme_stylebox_override("pressed", st)
		b.add_theme_color_override("font_color", p.fg)
	return b


func _clear(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


func _build_ui() -> void:
	_clear($Safe)
	var p: Dictionary = _pal()
	$Bg.color = p.bg

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	$Safe.add_child(root)
	ui.root = root

	var toast := Label.new()
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_color_override("font_color", p.fg)
	toast.add_theme_font_size_override("font_size", 14)
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	$Safe.add_child(toast)
	toast.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	toast.offset_bottom = -8
	ui.toast = toast


func _show(name: String) -> void:
	screen = name
	toast_text = ""
	_build_ui()
	match name:
		"menu":
			_draw_menu()
		"play":
			_draw_play()
		"shop":
			_draw_shop()
		"howto":
			_draw_howto()
		"win":
			_draw_win()
		"feedback":
			_draw_feedback()
	_refresh_toast()


func _theme_btn() -> Button:
	var b := _pill("Ночь" if is_day else "День", false)
	b.custom_minimum_size = Vector2(88, 40)
	b.pressed.connect(_on_theme_pressed)
	return b


func _draw_menu() -> void:
	var p: Dictionary = _pal()
	var root: VBoxContainer = ui.root

	var top := HBoxContainer.new()
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	top.add_child(_theme_btn())
	root.add_child(top)

	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var kicker := Label.new()
	kicker.text = "ГОЛОВОЛОМКА"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.add_theme_font_size_override("font_size", 12)
	kicker.add_theme_color_override("font_color", p.muted)
	var title := Label.new()
	title.text = "Цифры"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", p.fg)
	var sub := Label.new()
	sub.text = "Соединяйте одинаковые или дающие\nдесять. Очистите поле."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", p.muted)
	head.add_child(kicker)
	head.add_child(title)
	head.add_child(sub)
	root.add_child(head)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	stats.add_child(_stat_card(str(coins), "Монеты"))
	stats.add_child(_stat_card(str(games_won), "Побед"))
	stats.add_child(_stat_card("—" if best_moves < 0 else str(best_moves), "Рекорд"))
	root.add_child(stats)

	var play := _pill("▶  Играть", true)
	play.pressed.connect(_on_new_pressed)
	root.add_child(play)
	var howto := _pill("Правила", false)
	howto.pressed.connect(func() -> void: _show("howto"))
	root.add_child(howto)
	var shop := _pill("Лавка", false)
	shop.pressed.connect(func() -> void: _show("shop"))
	root.add_child(shop)
	var bug := _pill("Сообщить об ошибке", false)
	bug.pressed.connect(func() -> void: _show("feedback"))
	root.add_child(bug)


func _stat_card(value: String, label: String) -> PanelContainer:
	var p: Dictionary = _pal()
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _round_style(p.surface, 12))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var v := Label.new()
	v.text = value
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_theme_font_size_override("font_size", 22)
	v.add_theme_color_override("font_color", p.fg)
	var l := Label.new()
	l.text = label
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", p.muted)
	box.add_child(v)
	box.add_child(l)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_bottom", 12)
	pad.add_child(box)
	panel.add_child(pad)
	return panel


func _draw_play() -> void:
	var p: Dictionary = _pal()
	var root: VBoxContainer = ui.root

	var top := HBoxContainer.new()
	var menu_b := _pill("Меню", false)
	menu_b.custom_minimum_size = Vector2(72, 40)
	menu_b.pressed.connect(func() -> void: _show("menu"))
	top.add_child(menu_b)
	var mid := Label.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_theme_font_size_override("font_size", 13)
	mid.add_theme_color_override("font_color", p.muted)
	mid.text = "Ходы %d    Ещё %d" % [moves, _count_left()]
	top.add_child(mid)
	var coins_b := _pill(str(coins), false)
	coins_b.custom_minimum_size = Vector2(64, 40)
	coins_b.pressed.connect(func() -> void: _show("shop"))
	top.add_child(coins_b)
	top.add_child(_theme_btn())
	root.add_child(top)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	actions.add_child(_icon_btn("Назад", _on_undo_pressed))
	actions.add_child(_icon_btn(str(hints), _on_hint_pressed))
	actions.add_child(_icon_btn(str(adds_left), _on_add_pressed))
	actions.add_child(_icon_btn("Новая", _on_new_pressed))
	actions.add_child(_icon_btn("Баг", func() -> void: _show("feedback")))
	root.add_child(actions)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var board_wrap := PanelContainer.new()
	board_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_wrap.add_theme_stylebox_override("panel", _round_style(p.surface, 16))
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 6)
	pad.add_theme_constant_override("margin_top", 6)
	pad.add_theme_constant_override("margin_right", 6)
	pad.add_theme_constant_override("margin_bottom", 6)
	var board := VBoxContainer.new()
	board.add_theme_constant_override("separation", 4)
	for r in range(grid.size()):
		var row: Array = grid[r]
		var row_box := HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 4)
		for c in range(row.size()):
			row_box.add_child(_cell_btn(r, c, row[c]))
		if row.size() < COLS:
			var spacer := Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			spacer.size_flags_stretch_ratio = float(COLS - row.size())
			row_box.add_child(spacer)
		board.add_child(row_box)
	pad.add_child(board)
	board_wrap.add_child(pad)
	scroll.add_child(board_wrap)
	root.add_child(scroll)


func _icon_btn(text: String, cb: Callable) -> Button:
	var p: Dictionary = _pal()
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 48)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_stylebox_override("normal", _round_style(p.elevated, 12))
	b.add_theme_stylebox_override("hover", _round_style(p.elevated, 12))
	b.add_theme_stylebox_override("pressed", _round_style(p.elevated, 12))
	b.add_theme_color_override("font_color", p.muted)
	b.pressed.connect(cb)
	return b


func _cell_btn(r: int, c: int, val) -> Button:
	var p: Dictionary = _pal()
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 64)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 26)
	var pos := Vector2i(r, c)
	if val == null:
		btn.text = "#"
		btn.disabled = true
		btn.add_theme_color_override("font_disabled_color", Color(p.muted.r, p.muted.g, p.muted.b, 0.45))
		btn.add_theme_stylebox_override("disabled", _round_style(Color(0, 0, 0, 0), 6))
	else:
		btn.text = str(val)
		var st := _round_style(p.cell, 6)
		if selected == pos:
			st = _round_style(p.accent, 6)
			btn.add_theme_color_override("font_color", p.bg)
		else:
			btn.add_theme_color_override("font_color", p.fg)
		if hint_a == pos or hint_b == pos:
			st.border_width_left = 3
			st.border_width_top = 3
			st.border_width_right = 3
			st.border_width_bottom = 3
			st.border_color = p.ok
		btn.add_theme_stylebox_override("normal", st)
		btn.add_theme_stylebox_override("hover", st)
		btn.add_theme_stylebox_override("pressed", st)
		var rr := r
		var cc := c
		btn.pressed.connect(func() -> void: _tap(rr, cc))
	return btn


func _back_row(title: String, to := "menu") -> void:
	var p: Dictionary = _pal()
	var top := HBoxContainer.new()
	var back := _pill("Назад", false)
	back.custom_minimum_size = Vector2(88, 40)
	back.pressed.connect(func() -> void: _show(to))
	var t := Label.new()
	t.text = title
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 22)
	t.add_theme_color_override("font_color", p.fg)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(88, 1)
	top.add_child(back)
	top.add_child(t)
	top.add_child(spacer)
	ui.root.add_child(top)


func _draw_shop() -> void:
	var p: Dictionary = _pal()
	_back_row("Лавка")
	var note := Label.new()
	note.text = "Подсказки: %d. Покупки сохраняются на устройстве." % hints
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", p.muted)
	ui.root.add_child(note)
	_shop_row("3 подсказки", "50 монет", _buy_hints)
	_shop_row("+2 добавления", "40 монет", _buy_adds)
	_shop_row("Убрать рекламу", "Куплено" if ads_removed else "280 монет", _buy_no_ads)
	var h := Label.new()
	h.text = "За рекламу"
	h.add_theme_color_override("font_color", p.muted)
	ui.root.add_child(h)
	_shop_row("+50 монет", "Ролик", func() -> void: Ads.show_rewarded(_reward_coins))
	_shop_row("+2 добавления", "Ролик", func() -> void: Ads.show_rewarded(_reward_adds))


func _shop_row(title: String, price: String, cb: Callable) -> void:
	var p: Dictionary = _pal()
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, 56)
	b.focus_mode = Control.FOCUS_NONE
	var st := _round_style(p.surface, 16)
	st.border_width_left = 1
	st.border_width_top = 1
	st.border_width_right = 1
	st.border_width_bottom = 1
	st.border_color = Color(p.fg.r, p.fg.g, p.fg.b, 0.12)
	st.content_margin_left = 16
	st.content_margin_right = 16
	b.add_theme_stylebox_override("normal", st)
	b.add_theme_stylebox_override("hover", st)
	b.add_theme_stylebox_override("pressed", st)
	b.text = "%s    ·    %s" % [title, price]
	b.add_theme_color_override("font_color", p.fg)
	b.pressed.connect(cb)
	ui.root.add_child(b)


func _draw_howto() -> void:
	var p: Dictionary = _pal()
	_back_row("Правила")
	var lines := [
		"01 — Пара подходит, если цифры одинаковые или в сумме дают 10.",
		"02 — Одна строка или один столбец. Между ними только знаки #.",
		"03 — Крайняя справа и крайняя слева ниже — тоже пара. Пустые строки из одних # между ними не мешают.",
		"04 — «Добавить» дописывает оставшиеся цифры вниз, не добивая строку знаками #.",
	]
	for line in lines:
		var l := Label.new()
		l.text = line
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 16)
		l.add_theme_color_override("font_color", p.fg)
		ui.root.add_child(l)


func _draw_win() -> void:
	var p: Dictionary = _pal()
	var k := Label.new()
	k.text = "ПОЛЕ ЧИСТОЕ"
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	k.add_theme_color_override("font_color", p.muted)
	var t := Label.new()
	t.text = "Победа"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 48)
	t.add_theme_color_override("font_color", p.fg)
	var s := Label.new()
	s.text = "Ходов: %d" % moves
	if best_moves >= 0:
		s.text += "  ·  Рекорд: %d" % best_moves
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_color_override("font_color", p.muted)
	ui.root.add_child(k)
	ui.root.add_child(t)
	ui.root.add_child(s)
	var again := _pill("Ещё партию", true)
	again.pressed.connect(_on_new_pressed)
	ui.root.add_child(again)
	var menu := _pill("В меню", false)
	menu.pressed.connect(func() -> void: _show("menu"))
	ui.root.add_child(menu)


func _draw_feedback() -> void:
	var p: Dictionary = _pal()
	_back_row("Ошибка", "play" if not grid.is_empty() else "menu")
	var note := Label.new()
	note.text = "Нажми «Скопировать отчёт» — в буфер попадут поле, последняя неудачная пара и лог ходов."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", p.muted)
	ui.root.add_child(note)
	if last_fail != "":
		var fail := Label.new()
		fail.text = "Последняя неудачная пара: " + last_fail
		fail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fail.add_theme_color_override("font_color", p.fg)
		ui.root.add_child(fail)
	var copy := _pill("Сохранить и скопировать отчёт", true)
	copy.pressed.connect(_on_bug_pressed)
	ui.root.add_child(copy)


func _refresh_toast() -> void:
	if ui.has("toast"):
		ui.toast.text = toast_text


func _toast(msg: String) -> void:
	toast_text = msg
	_refresh_toast()


func _on_new_pressed() -> void:
	grid = []
	for row in INITIAL:
		grid.append(row.duplicate())
	selected = Vector2i(-1, -1)
	hint_a = Vector2i(-1, -1)
	hint_b = Vector2i(-1, -1)
	moves = 0
	adds_left = ADDS_PER_GAME + extra_adds
	extra_adds = 0
	history.clear()
	last_fail = ""
	_log("new_game")
	_show("play")


func _tap(r: int, c: int) -> void:
	var val = grid[r][c]
	if val == null:
		return
	if selected.x < 0:
		selected = Vector2i(r, c)
		_log("select %s@%d,%d" % [str(val), r, c])
		_show("play")
		return
	if selected.x == r and selected.y == c:
		selected = Vector2i(-1, -1)
		_log("deselect")
		_show("play")
		return
	var va = grid[selected.x][selected.y]
	if _can_match(selected.x, selected.y, r, c):
		history.append(_clone_grid())
		if history.size() > 40:
			history.pop_front()
		grid[selected.x][selected.y] = null
		grid[r][c] = null
		moves += 1
		coins += 1
		_log("match %s+%s (%d,%d)-(%d,%d)" % [str(va), str(val), selected.x, selected.y, r, c])
		selected = Vector2i(-1, -1)
		hint_a = Vector2i(-1, -1)
		hint_b = Vector2i(-1, -1)
		if _count_left() == 0:
			coins += 40
			games_won += 1
			if best_moves < 0 or moves < best_moves:
				best_moves = moves
			_log("win moves=%d" % moves)
			_save_meta()
			_show("win")
			return
		_save_meta()
		_show("play")
	else:
		last_fail = "%s@%d,%d — %s@%d,%d" % [str(va), selected.x, selected.y, str(val), r, c]
		_log("fail %s" % last_fail)
		selected = Vector2i(-1, -1)
		_toast("Нельзя соединить")
		_show("play")
		_toast("Нельзя соединить")


func _can_match(r1: int, c1: int, r2: int, c2: int) -> bool:
	if r1 == r2 and c1 == c2:
		return false
	if r1 >= grid.size() or r2 >= grid.size():
		return false
	if c1 >= grid[r1].size() or c2 >= grid[r2].size():
		return false
	var a = grid[r1][c1]
	var b = grid[r2][c2]
	if a == null or b == null:
		return false
	if not (a == b or int(a) + int(b) == 10):
		return false
	if r1 == r2:
		var mn = mini(c1, c2)
		var mx = maxi(c1, c2)
		for c in range(mn + 1, mx):
			if grid[r1][c] != null:
				return false
		return true
	if c1 == c2:
		var mn = mini(r1, r2)
		var mx = maxi(r1, r2)
		for r in range(mn + 1, mx):
			var row: Array = grid[r]
			if c1 >= row.size():
				continue
			if row[c1] != null:
				return false
		return true
	var top_r = mini(r1, r2)
	var bot_r = maxi(r1, r2)
	var top_c = c1 if r1 == top_r else c2
	var bot_c = c2 if r1 == top_r else c1
	if not _is_rightmost(top_r, top_c) or not _is_leftmost(bot_r, bot_c):
		return false
	for r in range(top_r + 1, bot_r):
		if r >= grid.size():
			return false
		for v in grid[r]:
			if v != null:
				return false
	return true


func _is_rightmost(r: int, c: int) -> bool:
	var row: Array = grid[r]
	for i in range(c + 1, row.size()):
		if row[i] != null:
			return false
	return true


func _is_leftmost(r: int, c: int) -> bool:
	var row: Array = grid[r]
	for i in range(0, c):
		if row[i] != null:
			return false
	return true


func _count_left() -> int:
	var n := 0
	for row in grid:
		for v in row:
			if v != null:
				n += 1
	return n


func _clone_grid() -> Array:
	var out: Array = []
	for row in grid:
		out.append(row.duplicate())
	return out


func _dump_board() -> String:
	var lines: PackedStringArray = PackedStringArray()
	for row in grid:
		var cells: PackedStringArray = PackedStringArray()
		for v in row:
			cells.append("#" if v == null else str(v))
		lines.append(" ".join(cells))
	return "\n".join(lines)


func _log(msg: String) -> void:
	action_log.append("%d %s" % [Time.get_unix_time_from_system(), msg])
	if action_log.size() > LOG_MAX:
		action_log.remove_at(0)


func _on_add_pressed() -> void:
	if adds_left <= 0:
		_toast("Нет добавлений — лавка или реклама")
		_log("add_denied")
		return
	var rem: Array = []
	for row in grid:
		for v in row:
			if v != null:
				rem.append(v)
	if rem.is_empty():
		return
	history.append(_clone_grid())
	for num in rem:
		if grid.is_empty() or grid[grid.size() - 1].size() >= COLS:
			grid.append([])
		grid[grid.size() - 1].append(num)
	adds_left -= 1
	selected = Vector2i(-1, -1)
	hint_a = Vector2i(-1, -1)
	hint_b = Vector2i(-1, -1)
	_log("add left=%d" % adds_left)
	if not ads_removed and adds_left % 2 == 0:
		Ads.show_interstitial()
	_show("play")


func _on_undo_pressed() -> void:
	if history.is_empty():
		return
	grid = history.pop_back()
	selected = Vector2i(-1, -1)
	hint_a = Vector2i(-1, -1)
	hint_b = Vector2i(-1, -1)
	_log("undo")
	_show("play")


func _on_hint_pressed() -> void:
	if hints <= 0:
		_toast("Нет подсказок — купите в лавке")
		return
	var pair = _find_hint()
	if pair == null:
		_toast("Ходов нет — добавьте")
		_log("hint_none")
		return
	hints -= 1
	hint_a = pair[0]
	hint_b = pair[1]
	_toast("Пара подсвечена")
	_log("hint")
	_save_meta()
	_show("play")
	_toast("Пара подсвечена")


func _find_hint():
	var cells: Array = []
	for r in range(grid.size()):
		for c in range(grid[r].size()):
			if grid[r][c] != null:
				cells.append(Vector2i(r, c))
	for i in range(cells.size()):
		for j in range(i + 1, cells.size()):
			var a: Vector2i = cells[i]
			var b: Vector2i = cells[j]
			if _can_match(a.x, a.y, b.x, b.y):
				return [a, b]
	return null


func _on_theme_pressed() -> void:
	is_day = not is_day
	_save_meta()
	_log("theme %s" % ("day" if is_day else "night"))
	_show(screen)


func _on_bug_pressed() -> void:
	var report := "Цифры баг-отчёт\n"
	report += "Ходы: %d  Осталось: %d  Добавлений: %d\n" % [moves, _count_left(), adds_left]
	if last_fail != "":
		report += "Последняя неудачная пара: %s\n" % last_fail
	report += "\nПоле:\n%s\n\nЛог:\n%s\n" % [_dump_board(), "\n".join(action_log)]
	DisplayServer.clipboard_set(report)
	_toast("Отчёт скопирован")
	_log("report")
	print(report)


func _buy_hints() -> void:
	if coins < 50:
		_toast("Не хватает монет")
		return
	coins -= 50
	hints += 3
	_save_meta()
	_toast("Куплено 3 подсказки")
	_show("shop")
	_toast("Куплено 3 подсказки")


func _buy_adds() -> void:
	if coins < 40:
		_toast("Не хватает монет")
		return
	coins -= 40
	extra_adds += 2
	if screen == "play":
		adds_left += 2
	_save_meta()
	_toast("+2 добавления")
	_show("shop")
	_toast("+2 добавления")


func _buy_no_ads() -> void:
	if ads_removed:
		return
	if coins < 280:
		_toast("Не хватает монет")
		return
	coins -= 280
	ads_removed = true
	_save_meta()
	_toast("Реклама отключена")
	_show("shop")
	_toast("Реклама отключена")


func _reward_coins() -> void:
	coins += 50
	_save_meta()
	_toast("+50 монет")
	_show("shop")
	_toast("+50 монет")


func _reward_adds() -> void:
	extra_adds += 2
	adds_left += 2
	_toast("+2 добавления")
	_show("shop")
	_toast("+2 добавления")


func _save_meta() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "coins", coins)
	cfg.set_value("meta", "hints", hints)
	cfg.set_value("meta", "ads_removed", ads_removed)
	cfg.set_value("meta", "is_day", is_day)
	cfg.set_value("meta", "games_won", games_won)
	cfg.set_value("meta", "best_moves", best_moves)
	cfg.save("user://tsifry.cfg")


func _load_meta() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://tsifry.cfg") != OK:
		return
	coins = int(cfg.get_value("meta", "coins", 80))
	hints = int(cfg.get_value("meta", "hints", 4))
	ads_removed = bool(cfg.get_value("meta", "ads_removed", false))
	is_day = bool(cfg.get_value("meta", "is_day", false))
	games_won = int(cfg.get_value("meta", "games_won", 0))
	best_moves = int(cfg.get_value("meta", "best_moves", -1))
