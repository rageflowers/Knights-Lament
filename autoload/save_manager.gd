extends Node
class_name SaveManager

const SAVE_DIR := "user://saves/"
const SLOT_COUNT := 3

func _ensure_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func _slot_path(slot: int) -> String:
	return "%sslot_%d.json" % [SAVE_DIR, slot]

func slot_exists(slot: int) -> bool:
	_ensure_dir()
	return FileAccess.file_exists(_slot_path(slot))

func load_slot(slot: int) -> bool:
	_ensure_dir()

	var path := _slot_path(slot)
	var exists := FileAccess.file_exists(path)
	print("[SAVE] load_slot(%d) path=%s exists=%s" % [slot, path, str(exists)])

	if not exists:
		return false

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		print("[SAVE] load_slot: open READ failed (null FileAccess)")
		return false

	var text := f.get_as_text()
	f.close()

	# Important: type the parsed value explicitly so it doesn't infer Variant and trip warnings-as-errors.
	var parsed: Variant = JSON.parse_string(text)

	if typeof(parsed) != TYPE_DICTIONARY:
		print("[SAVE] load_slot: JSON root was not a Dictionary, type=", typeof(parsed))
		return false

	GameState.from_dict(parsed as Dictionary)
	print("[SAVE] load_slot: success")
	return true

func save_slot(slot: int) -> bool:
	_ensure_dir()
	var path := _slot_path(slot)
	print("[SAVE] save_slot(", slot, ") path=", _slot_path(slot))

	var f := FileAccess.open(path, FileAccess.WRITE)
	print("[SAVE] open WRITE f=null? ", f == null)

	if f == null:
		return false

	var payload: Dictionary = GameState.to_dict()
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()
	print("[SAVE] wrote bytes, slot exists now? ", FileAccess.file_exists(_slot_path(slot)))

	return true

func delete_slot(slot: int) -> bool:
	_ensure_dir()
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(path) == OK

func slot_summary(slot: int) -> Dictionary:
	# lightweight peek for UI list
	_ensure_dir()
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}

	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}

	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	var d := parsed as Dictionary
	# return only what the menu needs
	return {
		"level": int(d.get("level", 1)),
		"xp": int(d.get("xp", 0)),
		"xp_to_next": int(d.get("xp_to_next", 50)),
		"lives": int(d.get("lives", 3)),
		"max_lives": int(d.get("max_lives", 3)),
		"campaign_index": int(d.get("campaign_index", 0)),
	}
