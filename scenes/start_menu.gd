extends Control

# ---- tune these once and forget them ----
const WAR_TABLE_SCENE := "res://war_table.tscn"
const AUTOSAVE_SLOT := 0
const FIRST_MANUAL_SLOT := 1
const MANUAL_SLOT_COUNT := 3  # slots 1..3
const NarrativeScript = preload("res://data/narratives.gd")


@onready var title: Label = $Root/Title
@onready var continue_btn: Button = $Root/Buttons/ContinueButton
@onready var new_btn: Button = $Root/Buttons/NewGameButton
@onready var load_btn: Button = $Root/Buttons/LoadButton
@onready var quit_btn: Button = $Root/Buttons/QuitButton
@onready var status: Label = $Root/Status

@onready var load_dialog: AcceptDialog = $LoadDialog
@onready var load_list: ItemList = $LoadDialog/LoadList

var pending_load_item_index: int = -1

func _ready() -> void:
	Presentation.set_background(
		load("res://assets/backgrounds/menus/start_menu.png"),
		Presentation.Context.START_MENU
	)
	if title: title.text = "KNIGHT'S LAMENT"
	if status: status.text = ""

	var has_save := (Save != null)

	if continue_btn: continue_btn.pressed.connect(_on_continue_pressed)
	if new_btn: new_btn.pressed.connect(_on_new_game_pressed)
	if load_btn: load_btn.pressed.connect(_on_load_pressed)
	if quit_btn: quit_btn.pressed.connect(func(): get_tree().quit())
	if load_list: load_list.item_activated.connect(_on_slot_activated)

	load_list.item_selected.connect(func(i: int) -> void:
		pending_load_item_index = i
	)
	load_dialog.confirmed.connect(func() -> void:
		_on_slot_confirmed()
	)
	_refresh_buttons()

	if not has_save:
		if status: status.text = "Save system not found (autoload missing)."
		if continue_btn: continue_btn.disabled = true
		if load_btn: load_btn.disabled = true

func _on_slot_confirmed() -> void:
	if pending_load_item_index < 0:
		status.text = "Select a slot first."
		return
	_on_slot_activated(pending_load_item_index)

func _refresh_buttons() -> void:
	var can_continue := false
	if Save != null:
		can_continue = Save.slot_exists(0)
	continue_btn.disabled = not can_continue

func _on_continue_pressed() -> void:
	# Continue = load slot 0, then go war table
	if Save == null:
		status.text = "Cannot continue: Save autoload not found."
		return

	if not Save.slot_exists(0):
		status.text = "No save in Slot 0."
		_refresh_buttons()
		return

	var ok: bool = Save.load_slot(0)
	if not ok:
		status.text = "Failed to load Slot 0."
		return

	status.text = "Loaded Slot 0."
	get_tree().change_scene_to_file(WAR_TABLE_SCENE)

func _on_new_game_pressed() -> void:
	# New Game means: reset GameState to defaults, then war table.
	# IMPORTANT: This does NOT delete existing saves. It's a fresh run in memory.
	# If you want "New Game wipes saves" later, we can add a confirm dialog.
	if GameState == null:
		status.text = "GameState autoload not found."
		return

	if GameState.has_method("reset_new_game"):
		GameState.reset_new_game()
	else:
		# fallback reset (minimal, add fields as needed)
		GameState.level = 1
		GameState.xp = 0
		GameState.xp_to_next = 50
		GameState.lives = 3
		GameState.max_lives = 3
		GameState.campaign_index = 0
		GameState.selected_battle_index = 0

		# perks
		GameState.perk_hp = 0
		GameState.perk_def = 0
		GameState.perk_potion_heal = 0
		GameState.perk_strike_dmg = 0
		GameState.perk_oath_dmg = 0
		GameState.perk_grace = 0
		if "perk_innate_regen" in GameState:
			GameState.perk_innate_regen = 0

		# progression flags
		GameState.spec_points_unspent = 0
		GameState.completed = [false, false, false, false, false, false, false, false, false]

	status.text = "New game started."

	# Intro narrative first, then it will route to War Table via next_scene on the last beat.
	var seq: Array = []
	if is_instance_valid(NarrativeDB) and NarrativeDB.has_method("get_sequence"):
		seq = NarrativeDB.get_sequence("intro")
	if seq.is_empty():
		get_tree().change_scene_to_file(WAR_TABLE_SCENE)
		return
	GameState.pending_narrative = seq
	get_tree().change_scene_to_file("res://scenes/narrative_scene.tscn")

func _on_load_pressed() -> void:
	# Show slot picker
	if Save == null:
		status.text = "Cannot load: Save autoload not found."
		return

	load_list.clear()

	for i in range(FIRST_MANUAL_SLOT, FIRST_MANUAL_SLOT + MANUAL_SLOT_COUNT):
		var exists := Save.slot_exists(i)
		var label := "Slot %d - %s" % [i, ("EXISTS" if exists else "EMPTY")]

		# If you added Save.get_slot_summary(i) returning a Dictionary, show it here.
		if exists and Save.has_method("get_slot_summary"):
			var s: Dictionary = Save.get_slot_summary(i)
			if s.size() > 0:
				label = "Slot %d - Lv %d  XP %d/%d  Lives %d/%d  Chapter %d" % [
					i,
					int(s.get("level", 1)),
					int(s.get("xp", 0)),
					int(s.get("xp_to_next", 50)),
					int(s.get("lives", 3)),
					int(s.get("max_lives", 3)),
					int(s.get("campaign_index", 0)) + 1
				]

		load_list.add_item(label)
		load_list.set_item_metadata(load_list.item_count - 1, i) # store REAL slot id

	# Default-select first entry so OK works immediately
	if load_list.item_count > 0:
		pending_load_item_index = 0
		load_list.select(0)
	else:
		pending_load_item_index = -1

	load_dialog.popup_centered()

func _on_slot_activated(item_index: int) -> void:
	if Save == null:
		status.text = "Cannot load: Save autoload not found."
		return

	var slot_id := int(load_list.get_item_metadata(item_index))

	if not Save.slot_exists(slot_id):
		status.text = "Slot %d is empty." % slot_id
		return

	var ok: bool = Save.load_slot(slot_id)
	if not ok:
		status.text = "Failed to load Slot %d." % slot_id
		return

	status.text = "Loaded Slot %d." % slot_id
	load_dialog.hide()
	get_tree().change_scene_to_file(WAR_TABLE_SCENE)
