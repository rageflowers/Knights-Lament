extends Control

@onready var chapter_list: ItemList = $Root/ChapterList
@onready var player_info: PanelContainer = $Root/InfoRow/PlayerInfo
@onready var selected_info: PanelContainer = $Root/InfoRow/SelectedInfo

@onready var start_button: Button = $Root/Buttons/StartBattleButton
@onready var perks_button: Button = $Root/Buttons/PerksButton
@onready var save_quit_button: Button = $Root/Buttons/SaveQuitButton
@onready var _level_val: Label = $"Root/InfoRow/PlayerInfo/SheetMargin/SheetVBox/StatsGrid/LevelVal"
@onready var _hp_val: Label    = $"Root/InfoRow/PlayerInfo/SheetMargin/SheetVBox/StatsGrid/HpVal"
@onready var _xp_val: Label    = $"Root/InfoRow/PlayerInfo/SheetMargin/SheetVBox/StatsGrid/XpVal"
@onready var _lives_val: Label = $"Root/InfoRow/PlayerInfo/SheetMargin/SheetVBox/StatsGrid/LivesVal"
@onready var _xp_bar: ProgressBar = $"Root/InfoRow/PlayerInfo/SheetMargin/SheetVBox/XpBar"
@onready var _chapter_line: Label  = $"Root/InfoRow/SelectedInfo/SelMargin/SelVBox/ChapterLine"
@onready var _status_line: Label   = $"Root/InfoRow/SelectedInfo/SelMargin/SelVBox/StatusLine"
@onready var _enemy_line: Label    = $"Root/InfoRow/SelectedInfo/SelMargin/SelVBox/EnemyLine"
@onready var _enemy_hp_line: Label = $"Root/InfoRow/SelectedInfo/SelMargin/SelVBox/EnemyHpLine"
@onready var _reward_line: Label   = $"Root/InfoRow/SelectedInfo/SelMargin/SelVBox/RewardLine"
@onready var _perk_grid: GridContainer = $"Root/InfoRow/PlayerInfo/SheetMargin/SheetVBox/PerkGrid"

const PERK_SPECS: Array[Dictionary] = [
	{"label": "HP", "field": "perk_hp"},
	{"label": "DEF", "field": "perk_def"},
	{"label": "Potion Heal", "field": "perk_potion_heal"},
	{"label": "Strike DMG", "field": "perk_strike_dmg"},
	{"label": "Oath DMG", "field": "perk_oath_dmg"},
	{"label": "Grace", "field": "perk_grace"},
	{"label": "Regen", "field": "perk_innate_regen"},
]

var chapters: Array[Dictionary] = []
var selected_index: int = 0

func _ready() -> void:
	_refresh_character_sheet()
	# --- Presentation: War Table background ---
	var tex := Backgrounds.get_war_table_bg()
	if tex:
		Presentation.set_background(tex, Presentation.Context.WAR_TABLE)
	else:
		push_warning("War Table background missing: res://assets/backgrounds/menus/war_table.png")

	chapters = preload("res://data/chapters.gd").all()

	# --- Save autoload (safe lookup; no global identifier needed) ---
	var save: Node = get_node_or_null("/root/Save")
	print("Save autoload alive:", save != null)
	if save != null:
		var exists: bool = bool(save.call("slot_exists", 0))
		print("slot0 exists:", exists)
	else:
		print("[WAR TABLE] Save autoload missing at runtime. Check Project Settings > Autoload name/path.")

	chapter_list.item_selected.connect(_on_item_selected)
	start_button.pressed.connect(_on_start_battle)

	perks_button.pressed.connect(func(): get_tree().change_scene_to_file("res://perk_menu.tscn"))

	save_quit_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/save_menu.tscn")
	)

	_refresh_list()
	_select_default()

func _gs_int(field: String, default_value: int = 0) -> int:
	var v = GameState.get(field)
	if v == null:
		return default_value
	return int(v)

func _refresh_character_sheet() -> void:
	# Level
	_level_val.text = str(GameState.level)

	# HP (computed, aligned with battle_screen.gd)
	var hp_cur := GameState.get_player_hp_current()
	var hp_max := GameState.get_player_hp_max()
	_hp_val.text = str(hp_cur) + " / " + str(hp_max)

	# XP
	var xp_cur := int(GameState.xp)
	var xp_next := int(GameState.xp_to_next)
	_xp_val.text = str(xp_cur) + " / " + str(xp_next)

	# XP Bar
	_xp_bar.min_value = 0
	_xp_bar.max_value = max(1, xp_next)
	_xp_bar.value = clamp(xp_cur, 0, int(_xp_bar.max_value))
	var pct := int(round(100.0 * float(xp_cur) / float(max(1, xp_next))))
	$"Root/InfoRow/PlayerInfo/SheetMargin/SheetVBox/XpBarRow/XpBarPct".text = str(pct) + "%"

	# Lives
	_lives_val.text = str(GameState.lives)
	
	# Perk Grid
	_refresh_perk_grid()

func _refresh_perk_grid() -> void:
	# Clear existing cells
	for child in _perk_grid.get_children():
		child.queue_free()

	# Build a stable 2-column grid (7 perks + 1 blank = 8 cells)
	var specs: Array[Dictionary] = PERK_SPECS.duplicate()
	while specs.size() < 8:
		specs.append({"label": "", "field": ""})

	for spec in specs:
		var label_text: String = str(spec.get("label", ""))
		var field: String = str(spec.get("field", ""))

		# --- Tile container ---
		var tile := PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Inner padding
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 6)
		margin.add_theme_constant_override("margin_right", 6)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		tile.add_child(margin)

		# Row with name left, value right
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.add_child(row)

		var name_label := Label.new()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.clip_text = true
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

		var val := Label.new()
		val.custom_minimum_size.x = 24
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

		# Compact font size for BOTH labels
		name_label.add_theme_font_size_override("font_size", 12)
		val.add_theme_font_size_override("font_size", 12)

		# Fill content
		if label_text == "":
			# Blank filler tile: keep it visually quiet
			name_label.text = ""
			val.text = ""
			tile.modulate.a = 0.15  # subtle empty slots
		else:
			var rank: int = _gs_int(field, 0)
			name_label.text = label_text
			val.text = str(rank)

		row.add_child(name_label)
		row.add_child(val)

		_perk_grid.add_child(tile)

func _refresh_list() -> void:
	chapter_list.clear()

	for i in range(chapters.size()):
		var ch := chapters[i]
		var status := _chapter_status(i)
		var line := "%s  [%s]" % [ch["title"], status]
		chapter_list.add_item(line)

	_refresh_character_sheet()

func _select_default() -> void:
	# default selection: current chapter
	selected_index = clamp(GameState.campaign_index, 0, chapters.size() - 1)
	chapter_list.select(selected_index)
	_update_selected_info()

func _on_item_selected(i: int) -> void:
	selected_index = i
	_update_selected_info()
	
func _update_selected_info() -> void:
	var idx: int = chapter_list.get_selected_items()[0] if chapter_list.get_selected_items().size() > 0 else -1

	if idx < 0:
		_chapter_line.text = "No chapter selected."
		_status_line.text = ""
		_enemy_line.text = ""
		_enemy_hp_line.text = ""
		_reward_line.text = ""
		start_button.disabled = true
		return

	var ch: Dictionary = chapters[idx]

	# --- Title ---
	var title: String = str(ch.get("title", "Unknown Chapter"))
	_chapter_line.text = "Chapter: " + title

	# --- Status ---
	var status: String = str(_chapter_status(idx))
	_status_line.text = "Status: " + status

	# --- Enemy ---
	var enemy_name: String = str(ch.get("enemy_name", "Unknown Enemy"))
	var base_enemy_hp: int = int(ch.get("enemy_hp", 0))
	var enemy_hp: int = GameState.scale_enemy_hp(base_enemy_hp)

	_enemy_line.text = "Enemy: " + enemy_name
	_enemy_hp_line.text = "Enemy HP: " + str(enemy_hp)

	# --- XP Reward (support multiple keys) ---
	var base_reward: int = int(ch.get("xp_reward", ch.get("xp", ch.get("reward_xp", 0))))
	var reward_xp: int = GameState.scale_xp_reward(base_reward)

	_reward_line.text = "XP Reward: " + str(reward_xp)

	# --- Start button gating (current OR completed replay) ---
	var unlocked: bool = (idx <= GameState.campaign_index)
	var replay: bool = bool(GameState.completed[idx])
	start_button.disabled = not (unlocked or replay)

func _chapter_status(i: int) -> String:
	if GameState.completed.size() == 9 and GameState.completed[i]:
		return "COMPLETED"
	if i == GameState.campaign_index:
		return "CURRENT"
	if i < GameState.campaign_index:
		# earlier but not marked completed (should be rare)
		return "UNLOCKED"
	return "LOCKED"

func _on_start_battle() -> void:
	# lock rule: allow current, or replay if completed
	var can_start := (selected_index <= GameState.campaign_index) or GameState.completed[selected_index]
	if not can_start:
		return

	# Store which chapter we're about to fight
	GameState.selected_battle_index = selected_index

	# Narrative milestone: BEFORE chapter 9 (only when starting the current chapter)
	var is_current := (selected_index == GameState.campaign_index)
	if is_current:
		var chapter_num := selected_index + 1 # 0-based index -> 1-based chapter number
		if GameState.maybe_start_narrative_before_chapter(chapter_num, "res://battle_screen.tscn"):
			return

	get_tree().change_scene_to_file("res://battle_screen.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_debug_skip"):
		# Jump to Chapter 9 (index 8)
		GameState.campaign_index = 8
		GameState.completed = [true, true, true, true, true, true, true, true, false]
		selected_index = GameState.campaign_index
		_refresh_list()
		_select_default()
		print("[DEV] Skipped to Chapter 9")
