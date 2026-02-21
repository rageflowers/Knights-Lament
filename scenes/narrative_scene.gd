extends Control

@onready var character_tex: TextureRect = $Character
@onready var narrative_text: RichTextLabel = $TextPanel/NarrativeText
@onready var text_panel: Control = $TextPanel

var panels: Array[Dictionary] = []
var index: int = 0
var next_scene_path: String = "res://war_table.tscn"
var _run_id: int = 0
var _bg_tween: Tween = null
var _text_tween: Tween = null
var _narr_id: String = ""
var _ng_dialog: ConfirmationDialog
var _ending := false
# Optional: if you want a built-in test when nothing is queued.
const ENABLE_FALLBACK_TEST := false

func _ready() -> void:
	# Make the label reliably visible and BBCode-capable
	narrative_text.visible = true
	narrative_text.bbcode_enabled = true

	print(
		"NARRATIVE READY: pending size =",
		GameState.pending_narrative.size(),
		" pending=",
		GameState.pending_narrative
	)

	# If nothing queued, don't show a fake panel—just leave.
	if GameState.pending_narrative.is_empty():
		get_tree().change_scene_to_file("res://war_table.tscn")
		return

	_narr_id = str(GameState.pending_narrative_id)
	GameState.pending_narrative_id = ""

	# Consume queued narrative
	var seq: Array = GameState.pending_narrative
	GameState.pending_narrative = []

	# Safety fallback only; real next_scene should come from panels[0]["next_scene"]
	play(seq, "res://war_table.tscn")

func play(sequence: Array, fallback_next_scene: String = "res://war_table.tscn") -> void:
	next_scene_path = fallback_next_scene
	panels.clear()
	Presentation.set_background(null, Presentation.Context.NARRATIVE)

	# Normalize incoming sequence -> Array[Dictionary]
	for item in sequence:
		if item is Dictionary:
			panels.append(item)

	index = 0

	if panels.is_empty():
		_end_sequence()
		return

	# Allow sequence[0] to set next scene globally
	if panels[0].has("next_scene"):
		next_scene_path = str(panels[0].get("next_scene", next_scene_path))

	_show_panel()


func _unhandled_input(event: InputEvent) -> void:
	if _ng_dialog != null and _ng_dialog.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_end_sequence()
		return

	if event.is_action_pressed("ui_accept"):
		_advance()

func _show_panel() -> void:
	if panels.is_empty():
		_end_sequence()
		return

	index = clamp(index, 0, panels.size() - 1)
	var p: Dictionary = panels[index]

	# Background texture (Presentation owns BG)
	var bg_path := str(p.get("bg", ""))
	if bg_path != "" and ResourceLoader.exists(bg_path):
		Presentation.set_background(load(bg_path) as Texture2D, Presentation.Context.NARRATIVE)
	# else: do nothing (blank bg means “no load attempt”)

	# Character texture
	var char_path := str(p.get("character", ""))
	if char_path != "" and ResourceLoader.exists(char_path):
		character_tex.texture = load(char_path) as Texture2D
		character_tex.visible = true
	else:
		character_tex.texture = null
		character_tex.visible = false

	# Text (BBCode-safe)
	var msg := str(p.get("text", ""))
	narrative_text.text = msg

	_run_id += 1
	_start_beat_run(_run_id, panels[index])

	# Per-panel override for next scene
	if p.has("next_scene"):
		next_scene_path = str(p.get("next_scene", next_scene_path))

func _start_beat_run(run_id: int, p: Dictionary) -> void:
	# Kill any previous tweens
	if _bg_tween: _bg_tween.kill()
	if _text_tween: _text_tween.kill()

	# Initial alphas
	var current_bg := str(p.get("bg", ""))
	var prev_bg := _panel_bg(index - 1)
	var bg_changed := (current_bg != "" and current_bg != prev_bg)

	if bg_changed:
		Presentation.set_bg_alpha(0.0)
	else:
		Presentation.set_bg_alpha(1.0)

	narrative_text.modulate.a = 0.0

	var pre_delay := float(p.get("pre_delay", 0.0))
	var fade_in := float(p.get("fade_in", 0.0))
	var hold := float(p.get("hold", 4.0))
	var fade_out := float(p.get("fade_out", 0.0))

	var msg := str(p.get("text", ""))
	# Hide text panel entirely when there's no text for this beat
	text_panel.visible = (msg.strip_edges() != "")
	if not text_panel.visible:
		narrative_text.text = ""

	var text_delay := float(p.get("text_delay", 0.0))
	var text_fade_in := float(p.get("text_fade_in", 0.0))
	var text_hold := float(p.get("text_hold", 0.0))
	var text_fade_out := float(p.get("text_fade_out", 0.0))

	# Kick off the async runner
	_run_beat_async(run_id, panels[index], bg_changed, pre_delay, fade_in, hold, fade_out, msg, text_delay, text_fade_in, text_hold, text_fade_out)

func _panel_bg(i: int) -> String:
	if i < 0 or i >= panels.size():
		return ""
	return str(panels[i].get("bg", ""))

func _run_beat_async(run_id: int, p: Dictionary, bg_changed: bool,
	pre_delay: float, fade_in: float, hold: float, fade_out: float,
	msg: String, text_delay: float, text_fade_in: float, text_hold: float, text_fade_out: float
) -> void:
	# Pre-delay (bg invisible)
	if pre_delay > 0.0:
		await get_tree().create_timer(pre_delay).timeout
		if run_id != _run_id: return

	# BG fade-in (only when bg changed)
	if bg_changed:
		if fade_in > 0.0:
			_bg_tween = create_tween()
			_bg_tween.tween_method(func(a): Presentation.set_bg_alpha(a), 0.0, 1.0, fade_in)
			await _bg_tween.finished
			if run_id != _run_id: return
		else:
			Presentation.set_bg_alpha(1.0)
	else:
		# same background: keep it solid, no fade-in
		Presentation.set_bg_alpha(1.0)
	
	if _text_tween:
		_text_tween.kill()
		narrative_text.modulate.a = 0.0

	# Kick off text concurrently (do NOT await)
	if msg != "":
		_run_text_async(run_id, msg, text_delay, text_fade_in, text_hold, text_fade_out)

	# BG hold
	if hold > 0.0:
		await get_tree().create_timer(hold).timeout
		if run_id != _run_id: return

	# BG fade out (skip if next panel uses same bg)
	var current_bg := str(p.get("bg", ""))
	var next_bg := _panel_bg(index + 1)
	var bg_changes := (next_bg == "" or next_bg != current_bg)

	if bg_changes and fade_out > 0.0:
		_bg_tween = create_tween()
		_bg_tween.tween_method(func(a): Presentation.set_bg_alpha(a), 1.0, 0.0, fade_out)
		await _bg_tween.finished
		if run_id != _run_id: return

	_advance()

func _run_text_async(run_id: int, _msg: String, text_delay: float, text_fade_in: float, text_hold: float, text_fade_out: float) -> void:
	# Delay
	if text_delay > 0.0:
		await get_tree().create_timer(text_delay).timeout
		if run_id != _run_id: return

	# Fade in
	if text_fade_in > 0.0:
		_text_tween = create_tween()
		_text_tween.tween_property(narrative_text, "modulate:a", 1.0, text_fade_in)
		await _text_tween.finished
		if run_id != _run_id: return
	else:
		narrative_text.modulate.a = 1.0

	# Hold
	if text_hold > 0.0:
		await get_tree().create_timer(text_hold).timeout
		if run_id != _run_id: return

	# Fade out
	if text_fade_out > 0.0:
		_text_tween = create_tween()
		_text_tween.tween_property(narrative_text, "modulate:a", 0.0, text_fade_out)
		await _text_tween.finished
		if run_id != _run_id: return
	else:
		narrative_text.modulate.a = 0.0

func _advance() -> void:
	_run_id += 1  # invalidates any running beat

	if _bg_tween: _bg_tween.kill()
	if _text_tween: _text_tween.kill()

	index += 1
	if index >= panels.size():
		_end_sequence()
	else:
		_show_panel()

func _end_sequence() -> void:
	if _ending: return
	_ending = true
	if _narr_id == "after_ch9":
		_show_ngplus_popup()
		return
	get_tree().change_scene_to_file(next_scene_path)
	
func _show_ngplus_popup() -> void:
	_run_id += 1
	if _bg_tween: _bg_tween.kill()
	if _text_tween: _text_tween.kill()
	if _ng_dialog == null:
		_ng_dialog = ConfirmationDialog.new()
		_ng_dialog.title = "New Game+"
		_ng_dialog.ok_button_text = "Next Tier"
		_ng_dialog.cancel_button_text = "Exit Game"
		_ng_dialog.confirmed.connect(_on_ngplus_next_tier)
		_ng_dialog.canceled.connect(_on_ngplus_exit)
		add_child(_ng_dialog)

	var tier_now := int(GameState.ng_tier)

	_ng_dialog.dialog_text = \
		"Enter the next tier?\n\n" + \
		"Enemies: +100% HP per tier\n" + \
		"Rewards: +75% XP per tier\n\n" + \
		"Current tier: " + str(tier_now) + " \u2192 " + str(tier_now + 1)

	_ng_dialog.popup_centered()

func _on_ngplus_next_tier() -> void:
	# You’ll wire this to whatever you named it in GameState
	if GameState.has_method("enter_next_tier"):
		GameState.enter_next_tier()
	elif GameState.has_method("begin_new_game_plus"):
		GameState.begin_new_game_plus()
	else:
		# fallback: at least reset campaign if you have that function
		if GameState.has_method("reset_campaign_progress"):
			GameState.reset_campaign_progress()

	# Start the intro again
	var seq: Array = []
	if is_instance_valid(NarrativeDB) and NarrativeDB.has_method("get_sequence"):
		seq = NarrativeDB.get_sequence("intro")

	GameState.pending_narrative_id = "intro"
	GameState.pending_narrative = seq

	get_tree().change_scene_to_file("res://scenes/narrative_scene.tscn")

func _on_ngplus_exit() -> void:
	get_tree().quit()
