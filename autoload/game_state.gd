extends Node

const NARRATIVE_SCENE := "res://scenes/narrative_scene.tscn"

# ---- Save payload (weekend scope) ----
var level: int = 1
var xp: int = 0
var xp_to_next: int = 50

var lives: int = 3
var max_lives: int = 3
var ng_tier: int = 0  # 0 = normal run, 1 = Tier 2, etc.

# Used to let NarrativeScene know what it is playing (so it can show the NG+ popup after after_ch9)
var pending_narrative_id: String = ""
var pending_narrative_fallback_next: String = "res://war_table.tscn"

var campaign_index: int = 0 # 0..8 current chapter
var completed: Array[bool] = [] # len 9
var selected_battle_index: int = 0

var seen_interlude_1: bool = false
var pending_narrative: Array = []

var spec_points_unspent: int = 0

# perks
var perk_hp: int = 0
var perk_def: int = 0
var perk_potion_heal: int = 0
var perk_strike_dmg: int = 0
var perk_oath_dmg: int = 0
var perk_grace: int = 0
var perk_innate_regen: int = 0  # +0.5% max HP healed at start of player turn per rank
# ---- Narrative triggers (one-time milestones) ----
# id -> true
var seen_narratives: Dictionary = {}

func has_seen_narrative(id: String) -> bool:
	return seen_narratives.get(id, false)

func mark_seen_narrative(id: String) -> void:
	seen_narratives[id] = true

# Chapter milestone mapping (IDs must match your Narratives.get_sequence() keys)
# These are "chapter numbers" (2,5,9), not 0-based indices.
const NARR_AFTER_CHAPTER := {
	2: "after_ch2",
	5: "after_ch5",
	9: "after_ch9",
}

const NARR_BEFORE_CHAPTER := {
	9: "before_ch9",
}

func get_player_hp_max() -> int:
	# Mirrors battle_screen.gd _recompute_player_stats()
	var base_hp := int(round(40.0 + 3.6 * float(level - 1)))
	var hp_mult := 1.0 + (0.01 * float(perk_hp))
	return int(round(float(base_hp) * hp_mult))

func get_player_hp_current() -> int:
	# War Table "ready state" (battles start full-heal)
	return get_player_hp_max()

func enter_next_tier() -> void:
	ng_tier += 1
	reset_campaign_progress()
	lives = max_lives  # optional but usually feels right
	
func maybe_start_narrative_after_chapter(chapter_num: int, next_scene: String) -> bool:
	var id: String = NARR_AFTER_CHAPTER.get(chapter_num, "")
	if id == "" or has_seen_narrative(id):
		return false
	mark_seen_narrative(id)
	start_narrative_id(id, next_scene)
	return true

func maybe_start_narrative_before_chapter(chapter_num: int, next_scene: String) -> bool:
	var id: String = NARR_BEFORE_CHAPTER.get(chapter_num, "")
	if id == "" or has_seen_narrative(id):
		return false
	mark_seen_narrative(id)
	start_narrative_id(id, next_scene)
	return true

func _ready() -> void:
	if completed.is_empty():
		completed.resize(9)
		for i in range(9):
			completed[i] = false

	set_process_unhandled_input(true)

func new_game() -> void:
	level = 1
	xp = 0
	xp_to_next = 50
	lives = 3
	max_lives = 3
	campaign_index = 0
	spec_points_unspent = 0

	perk_hp = 0
	perk_def = 0
	perk_potion_heal = 0
	perk_strike_dmg = 0
	perk_oath_dmg = 0
	perk_grace = 0
	perk_innate_regen = 0

	completed.clear()
	completed.resize(9)
	for i in range(9):
		completed[i] = false
	seen_narratives.clear()
	pending_narrative = []

		
func to_dict() -> Dictionary:
	return {
		"level": level,
		"xp": xp,
		"xp_to_next": xp_to_next,

		"lives": lives,
		"max_lives": max_lives,

		"campaign_index": campaign_index,
		"completed": completed.duplicate(),
		"seen_interlude_1": seen_interlude_1,
		"seen_narratives": seen_narratives.duplicate(),

		"spec_points_unspent": spec_points_unspent,

		"perk_hp": perk_hp,
		"perk_def": perk_def,
		"perk_potion_heal": perk_potion_heal,
		"perk_strike_dmg": perk_strike_dmg,
		"perk_oath_dmg": perk_oath_dmg,
		"perk_grace": perk_grace,
		# "perk_innate_regen": perk_innate_regen, # if you added it

		"selected_battle_index": selected_battle_index,
	}

func from_dict(d: Dictionary) -> void:
	level = int(d.get("level", 1))
	xp = int(d.get("xp", 0))
	xp_to_next = int(d.get("xp_to_next", 50))

	lives = int(d.get("lives", 3))
	max_lives = int(d.get("max_lives", 3))

	campaign_index = int(d.get("campaign_index", 0))

	var raw_completed = d.get("completed", [])
	completed = []

	if raw_completed is Array:
		for v in raw_completed:
			completed.append(bool(v))

	# Normalize length (always 9 chapters)
	if completed.size() != 9:
		var fixed: Array[bool] = []
		fixed.resize(9)
		for i in range(9):
			fixed[i] = (i < completed.size() and completed[i])
		completed = fixed

	seen_interlude_1 = bool(d.get("seen_interlude_1", false))
	seen_narratives = {}
	var raw_seen = d.get("seen_narratives", {})
	if raw_seen is Dictionary:
		for k in raw_seen.keys():
			seen_narratives[str(k)] = bool(raw_seen[k])

	spec_points_unspent = int(d.get("spec_points_unspent", 0))

	perk_hp = int(d.get("perk_hp", 0))
	perk_def = int(d.get("perk_def", 0))
	perk_potion_heal = int(d.get("perk_potion_heal", 0))
	perk_strike_dmg = int(d.get("perk_strike_dmg", 0))
	perk_oath_dmg = int(d.get("perk_oath_dmg", 0))
	perk_grace = int(d.get("perk_grace", 0))
	# perk_innate_regen = int(d.get("perk_innate_regen", 0)) # if you added it

	selected_battle_index = int(d.get("selected_battle_index", 0))

# ---- XP / level helpers ----
func add_xp(amount: int) -> bool:
	xp += amount
	var leveled := false
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		spec_points_unspent += 1
		max_lives = 3 + int(floor(float(level) / 10.0)) # +1 every 10 levels
		lives = min(lives, max_lives)
		xp_to_next = int(round(50.0 + 20.0 * float(level - 1)))
		leveled = true
	return leveled

func _unhandled_input(event: InputEvent) -> void:

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		_debug_boost_to_level(10)
		print("[DEBUG] F10 boost -> level=", level, " xp=", xp, "/", xp_to_next, " spec_points=", spec_points_unspent)

func _debug_boost_to_level(target_level: int) -> void:
	while level < target_level:
		var needed: int = maxi(xp_to_next - xp, 1)
		add_xp(needed)

	# DEBUG convenience: refill lives to the new cap
	lives = max_lives

	print("[DEBUG] F10 boost -> level=", level, " xp=", xp, "/", xp_to_next,
		" lives=", lives, "/", max_lives, " spec=", spec_points_unspent)


func lose_life() -> void:
	lives = max(lives - 1, 0)

func can_revive() -> bool:
	# Final battle disables revival
	return campaign_index < 8

func start_narrative(sequence: Array, next_scene: String = "res://war_table.tscn") -> void:
	# Normalize to Array[Dictionary]
	var seq: Array = []
	for item in sequence:
		if item is Dictionary:
			seq.append(item)

	if seq.is_empty():
		# If there's nothing to show, just go where we were headed.
		get_tree().change_scene_to_file(next_scene)
		return

	# Ensure the sequence has a global next_scene (your NarrativeScene already supports this on panels[0])
	if not seq[0].has("next_scene"):
		var first: Dictionary = seq[0].duplicate()
		first["next_scene"] = next_scene
		seq[0] = first

	pending_narrative = seq
	get_tree().change_scene_to_file(NARRATIVE_SCENE)

func start_narrative_id(id: String, next_scene: String = "res://war_table.tscn") -> void:
	# Get sequence panels from NarrativeDB
	var seq: Array = []
	if is_instance_valid(NarrativeDB) and NarrativeDB.has_method("get_sequence"):
		seq = NarrativeDB.get_sequence(id)

	if seq.is_empty():
		# Nothing to show; go straight where we intended
		get_tree().change_scene_to_file(next_scene)
		return

	# Ensure the narrative knows where to go afterward.
	# NarrativeScene reads next_scene from panels[0].
	if seq[0] is Dictionary:
		var d: Dictionary = (seq[0] as Dictionary).duplicate(true)
		d["next_scene"] = next_scene
		seq[0] = d
	else:
		seq[0] = {"text": "", "bg": "", "character": "", "next_scene": next_scene}

	# Queue and go
	pending_narrative_id = id
	pending_narrative = seq
	get_tree().change_scene_to_file("res://scenes/narrative_scene.tscn")

func enemy_hp_multiplier() -> float:
	# +100% HP each tier:
	# tier 0 => 1.0x
	# tier 1 => 2.0x
	# tier 2 => 3.0x
	return 1.0 + float(ng_tier) * 1.0

func xp_multiplier() -> float:
	# +75% XP each tier:
	# tier 0 => 1.0x
	# tier 1 => 1.75x
	# tier 2 => 2.50x
	return 1.0 + float(ng_tier) * 0.75

func scale_enemy_hp(base_hp: int) -> int:
	return int(round(float(base_hp) * enemy_hp_multiplier()))

func scale_xp_reward(base_xp: int) -> int:
	return int(round(float(base_xp) * xp_multiplier()))

func reset_campaign_progress() -> void:
	campaign_index = 0
	selected_battle_index = 0

	completed.resize(9)
	for i in range(9):
		completed[i] = false

	# So interludes can replay each tier (recommended for NG+ loop)
	seen_narratives.clear()

func start_new_game_plus_next_tier() -> void:
	ng_tier += 1
	reset_campaign_progress()
	# Optional: refill lives for the new run (purely mechanical convenience)
	lives = max_lives

func queue_narrative(id: String, _fallback_next_scene: String = "res://war_table.tscn") -> void:
	pending_narrative_id = id
	pending_narrative = NarrativeDB.get_sequence(id)

	# If you use next_scene inside beats, great. If not, NarrativeScene's play(..., fallback) covers it.
	# (No extra fields needed here.)
