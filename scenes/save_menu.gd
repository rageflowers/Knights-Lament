extends Control

const MAIN_MENU := "res://scenes/start_menu.tscn"
const WAR_TABLE := "res://war_table.tscn"

const SLOT_START := 1   # manual slots start here
const SLOT_COUNT := 3   # slots 1..3

@onready var save_list: ItemList = $Root/SaveList
@onready var save_btn: Button = $Root/Buttons/SaveButton
@onready var back_btn: Button = $Root/Buttons/BackButton
@onready var exit_btn: Button = $Root/Buttons/ExitButton
@onready var status: Label = $Root/Status

var selected_slot: int = -1
var did_save_this_visit: bool = false

func _ready() -> void:
	Presentation.set_background(
		load("res://assets/backgrounds/menus/save_game.png"),
		Presentation.Context.SAVE_MENU
	)
	status.text = ""
	exit_btn.disabled = true
	did_save_this_visit = false

	if Save == null:
		status.text = "Save system not available."
		save_btn.disabled = true
		back_btn.disabled = false
		exit_btn.disabled = false # still allow quitting to main menu if saves are broken
		return

	_refresh_list()

	save_list.item_selected.connect(func(item_index: int) -> void:
		selected_slot = int(save_list.get_item_metadata(item_index))

		# Optional: if you want Exit enabled after selecting any slot (even before saving),
		# you can enable it here. If you ONLY want it after a save, delete this block.
		if did_save_this_visit:
			exit_btn.disabled = false
	)

	save_btn.pressed.connect(_on_save_pressed)

	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(WAR_TABLE)
	)

	exit_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(MAIN_MENU)
	)

func _refresh_list() -> void:
	save_list.clear()

	for i in range(SLOT_START, SLOT_START + SLOT_COUNT):
		var exists := Save.slot_exists(i)
		var label := "Slot %d - %s" % [i, ("EXISTS" if exists else "EMPTY")]

		if exists and Save.has_method("get_slot_summary"):
			var s: Dictionary = Save.get_slot_summary(i)
			if s.size() > 0:
				label = "Slot %d - Lv %d  Chapter %d" % [
					i,
					int(s.get("level", 1)),
					int(s.get("campaign_index", 0)) + 1
				]

		save_list.add_item(label)
		save_list.set_item_metadata(save_list.item_count - 1, i) # store REAL slot id

func _on_save_pressed() -> void:
	if Save == null:
		status.text = "Save system not available."
		return

	if selected_slot < SLOT_START:
		status.text = "Select a slot to save."
		return

	var ok: bool = Save.save_slot(selected_slot)
	if not ok:
		status.text = "Save failed."
		return

	status.text = "Saved to Slot %d." % selected_slot

	# mark + enable exit after successful save
	did_save_this_visit = true
	exit_btn.disabled = false

	# refresh UI so EXISTS/EMPTY updates immediately
	_refresh_list()

	# re-select the slot you just saved to
	var item_index := selected_slot - SLOT_START
	if item_index >= 0 and item_index < save_list.item_count:
		save_list.select(item_index)
		save_list.ensure_current_is_visible()
