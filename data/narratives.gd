extends Node
class_name Narratives

const NARR_ROOT := "res://assets/backgrounds/narrative"

func make_panels(bg_paths: Array, texts: Array = []) -> Array:
	var panels: Array = []
	for i in range(bg_paths.size()):
		var p: Dictionary = {
			"bg": str(bg_paths[i]),
			"character": "",
			"text": ""
		}
		if i < texts.size():
			p["text"] = str(texts[i])
		panels.append(p)
	return panels

func _folder_for(id: String) -> String:
	return NARR_ROOT.path_join(id)

func get_sequence(id: String) -> Array:
	var folder := _folder_for(id)

	# If beats.gd exists, use authored beats
	var beats_path := folder.path_join("beats.gd")
	if ResourceLoader.exists(beats_path):
		return _sequence_from_beats(folder, id)

	# Fallback: contiguous numbered frames (no beats authored)
	return panels_from_numbered(folder, id)

func _sequence_from_beats(folder: String, id: String, pad: int = 4) -> Array:
	var data := _load_beats(folder)
	var defaults_any = data.get("defaults", {})
	var defaults: Dictionary = defaults_any if defaults_any is Dictionary else {}
	var beats: Array = data.get("beats", [])

	var panels: Array = []
	for b in beats:
		if not (b is Dictionary):
			continue

		# Resolve filename
		var fname := ""
		if b.has("file"):
			fname = str(b["file"])
		else:
			var frame := int(b.get("frame", 0))
			fname = "%s_%0*d.png" % [id, pad, frame]

		var path := folder.path_join(fname)
		if not ResourceLoader.exists(path):
			push_warning("Narrative missing frame: " + path)
			continue

		# Merge defaults -> beat overrides
		var p: Dictionary = defaults.duplicate(true)
		for k in b.keys():
			p[k] = b[k]

		# Normalize into NarrativeScene panel format
		p["bg"] = path
		if not p.has("character"):
			p["character"] = ""
		if not p.has("text"):
			p["text"] = ""

		panels.append(p)

	return panels

func _load_beats(folder: String) -> Dictionary:
	var beats_path := folder.path_join("beats.gd")
	if not ResourceLoader.exists(beats_path):
		return {}

	var script := load(beats_path)
	if script == null:
		return {}

	var obj = script.new()
	if obj == null:
		return {}

	var defaults = obj.get("defaults")
	var beats = obj.get("beats")

	return {
		"defaults": defaults if defaults is Dictionary else {},
		"beats": beats if beats is Array else []
	}

func panels_from_numbered(folder: String, prefix: String, pad: int = 4, start_index: int = 1, max_frames: int = 9999, texts_by_file: Dictionary = {}) -> Array:
	var panels: Array = []

	for i in range(start_index, max_frames + 1):
		var fname := "%s_%0*d.png" % [prefix, pad, i]
		var path := folder.path_join(fname)

		# Export-proof existence check
		if not ResourceLoader.exists(path):
			# Stop at first missing frame (assumes contiguous numbering)
			break

		var text := ""
		if texts_by_file.has(fname):
			text = str(texts_by_file[fname])

		panels.append({
			"bg": path,
			"character": "",
			"text": text
		})

	return panels
