extends Control

enum BattleState { PLAYER_TURN, ENEMY_TURN, BATTLE_OVER }
enum Intent { LIGHT, HEAVY }
enum Boon { WRATH, AEGIS, REGEN }

const BattleActorScene := preload("res://battle_actor.tscn")

# -----------------------------
# UI (bottom half)
# -----------------------------
@onready var log_label: RichTextLabel = $RootVBox/UIFrame/UI/UILayout/TextLog

@onready var player_top_bar: ProgressBar = $RootVBox/UIFrame/UI/UILayout/TopBarsRow/PlayerTopBar
@onready var enemy_top_bar: ProgressBar = $RootVBox/UIFrame/UI/UILayout/TopBarsRow/EnemyTopBar
@onready var enemy_name_label: Label = $RootVBox/UIFrame/UI/UILayout/HUDRow/RightHUD/EnemyNameLabel
@onready var intent_label: Label = $RootVBox/UIFrame/UI/UILayout/HUDRow/RightHUD/IntentLabel

@onready var oath_bar: ProgressBar = $RootVBox/UIFrame/UI/UILayout/HUDRow/LeftHUD/TacticalDisp/OathBar
@onready var oath_charges_label: Label = $RootVBox/UIFrame/UI/UILayout/HUDRow/LeftHUD/TacticalDisp/OathChargesLabel

@onready var grace_bar: ProgressBar = $RootVBox/UIFrame/UI/UILayout/HUDRow/LeftHUD/TacticalDisp/GraceBar
@onready var potions_label: Label = $RootVBox/UIFrame/UI/UILayout/HUDRow/LeftHUD/TacticalDisp/PotionsLabel

@onready var strike_button: Button = $RootVBox/UIFrame/UI/UILayout/ActionMenu/StrikeButton
@onready var guard_button: Button = $RootVBox/UIFrame/UI/UILayout/ActionMenu/GuardButton
@onready var oath_button: Button = $RootVBox/UIFrame/UI/UILayout/ActionMenu/OathButton
@onready var potion_button: Button = $RootVBox/UIFrame/UI/UILayout/ActionMenu/PotionButton
@onready var pray_button: Button = $RootVBox/UIFrame/UI/UILayout/ActionMenu/PrayButton

# Oath micro prompt stays directly under UI (NOT under UILayout)
@onready var oath_prompt: PanelContainer = $RootVBox/UIFrame/UI/OathSpendPrompt
@onready var spend1_button: Button = $RootVBox/UIFrame/UI/OathSpendPrompt/VBoxContainer/ButtonsRow/Spend1Button
@onready var spend2_button: Button = $RootVBox/UIFrame/UI/OathSpendPrompt/VBoxContainer/ButtonsRow/Spend2Button

var oath_prompt_open: bool = false
const LOG_MAX_LINES := 80
var log_lines: Array[String] = []

# -----------------------------
# Stage (top half)
# -----------------------------
@onready var player_actor: Node2D = $RootVBox/StageFrame/SubViewportContainer/StageViewport/Stage/PlayerActor
var enemy_actor: BattleActor
@onready var player_anchor: Marker2D = $RootVBox/StageFrame/SubViewportContainer/StageViewport/Stage/PlayerAnchor
@onready var enemy_anchor: Marker2D = $RootVBox/StageFrame/SubViewportContainer/StageViewport/Stage/EnemyAnchor

@onready var player_sprite: AnimatedSprite2D = $RootVBox/StageFrame/SubViewportContainer/StageViewport/Stage/PlayerActor/AnimatedSprite2D
@onready var stage_viewport: SubViewport = $RootVBox/StageFrame/SubViewportContainer/StageViewport
@onready var stage_container: SubViewportContainer = $RootVBox/StageFrame/SubViewportContainer

# -----------------------------
# Progression (weekend version)
# -----------------------------
var level: int = 1
var xp: int = 0
var xp_to_next: int = 50
var spec_points_unspent: int = 0

# Valor perk(Specialize) ranks (minimal storage for now)
var perk_hp: int = 0            # +1% max hp per rank
var perk_def: int = 0           # +1% damage reduction per rank
var perk_potion_heal: int = 0   # +1% absolute potion heal per rank
var perk_strike_dmg: int = 0    # +0.5% strike damage per rank
var perk_oath_dmg: int = 0      # +3% oathbound damage per rank
var perk_grace: int = 0         # reduces grace threshold (80% -> 79% -> ...)

# -----------------------------
# Battle runtime
# -----------------------------
signal battle_finished(victory: bool)

var chapter_index: int = 0
var chapter_xp_reward: int = 0

var state: int = BattleState.PLAYER_TURN
var battle_over: bool = false

var player_name: String = "Sir Tigris"
var player_hp_max: int = 40
var player_hp: int = 40
var guarded: bool = false

var enemy_name: String = "Cogan Linebreaker"
var enemy_hp_max: int = 45
var enemy_hp: int = 45
var enemy_intent: int = Intent.LIGHT

# Oath system (threshold == max hp)
var oath_points: int = 0
var oath_charges: int = 0
const OATH_CHARGE_MAX := 2

# Potions & grace
var potions: int = 3
var grace_points: int = 0

# Boons: stackable but not same kind
var boon_turns := {
	Boon.WRATH: 0,
	Boon.AEGIS: 0,
	Boon.REGEN: 0,
}

func _ready() -> void:
	randomize()

	# --- Ensure SubViewport is rendering + transparent (no gray box) ---
	stage_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	stage_viewport.transparent_bg = true
	stage_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

	# IMPORTANT: wait one frame so container layout has finalized, then size viewport from the actual rect
	await get_tree().process_frame
	stage_viewport.size = stage_container.get_rect().size

	# --- Pull selected chapter from War Table ---
	var chapters = preload("res://data/chapters.gd")
	var ch: Dictionary = chapters.get_chapter(GameState.selected_battle_index)

	# Sync battle vars (enemy_name, enemy_hp, xp reward, etc.)
	setup_from_chapter(ch)

	# --- Stage reference ---
	var stage: Node2D = $RootVBox/StageFrame/SubViewportContainer/StageViewport/Stage

	# Hide legacy placeholder if it still exists in the scene
	var legacy_enemy := stage.get_node_or_null("Enemy")
	if legacy_enemy:
		legacy_enemy.visible = false

	# --- Replace EnemyActor with a fresh BattleActor instance ---
	var old_enemy := stage.get_node_or_null("EnemyActor")
	if old_enemy:
		old_enemy.queue_free()

	enemy_actor = BattleActorScene.instantiate() as BattleActor
	if enemy_actor == null:
		push_error("battle_actor.tscn did not instantiate as BattleActor. Ensure battle_actor.gd is attached to the ROOT node and uses class_name BattleActor.")
		return

	enemy_actor.name = "EnemyActor"
	stage.add_child(enemy_actor)

	# Ensure draw order
	stage.move_child(enemy_actor, stage.get_child_count() - 1)
	enemy_actor.z_as_relative = false
	enemy_actor.z_index = 1000

	# --- Place actors at anchors (LOCAL to Stage/SubViewport) ---
	player_actor.position = player_anchor.position
	enemy_actor.position = enemy_anchor.position

	# --- Apply enemy sprite ---
	enemy_actor.apply_enemy(ch)

	# Player placeholder tint (until you have player sprites)
	# Load player frames & play idle
	var player_frames = preload("res://assets/sprites/player/tigris_idle_frames.tres")
	player_sprite.sprite_frames = player_frames
	player_sprite.play("idle")

	# --- Presentation: background via registry ---
	var bg := Backgrounds.get_battle_bg(int(GameState.selected_battle_index))
	if bg:
		Presentation.set_background(bg, Presentation.Context.BATTLE)
	else:
		push_warning("Battle background missing for chapter index: %s" % str(GameState.selected_battle_index))

	# --- Sync progression from GameState ---
	level = GameState.level
	perk_hp = GameState.perk_hp
	perk_def = GameState.perk_def
	perk_potion_heal = GameState.perk_potion_heal
	perk_strike_dmg = GameState.perk_strike_dmg
	perk_oath_dmg = GameState.perk_oath_dmg
	perk_grace = GameState.perk_grace

	_recompute_player_stats()
	player_hp = player_hp_max

	# --- Hook buttons ---
	strike_button.pressed.connect(_on_strike)
	guard_button.pressed.connect(_on_guard)
	oath_button.pressed.connect(_on_oath)
	potion_button.pressed.connect(_on_potion)
	pray_button.pressed.connect(_on_pray)

	battle_finished.connect(_on_battle_finished)

	# --- Oath prompt ---
	oath_prompt.visible = false
	spend1_button.pressed.connect(func(): _confirm_oath_spend(1))
	spend2_button.pressed.connect(func(): _confirm_oath_spend(2))

	_start_battle()
	_refresh_ui()


# -----------------------------
# Stats helpers
# -----------------------------
func _recompute_player_stats() -> void:
	# Linear HP progression: L1=40, L100≈396
	var base_hp := int(round(40.0 + 3.6 * float(level - 1)))

	# +1% max hp per perk rank
	var hp_mult := 1.0 + (0.01 * float(perk_hp))
	player_hp_max = int(round(float(base_hp) * hp_mult))

	# Clamp current hp to new max
	player_hp = clamp(player_hp, 0, player_hp_max)

func _oath_threshold() -> int:
	return player_hp_max

func _grace_ratio() -> float:
	# Base 80%, reduce 1% per rank (min clamp so it can’t get silly)
	return max(0.50, 0.80 - 0.01 * float(perk_grace))

func _grace_threshold() -> int:
	return int(round(float(player_hp_max) * _grace_ratio()))

func setup_from_chapter(ch: Dictionary) -> void:
	chapter_index = int(ch.get("id", 0))
	enemy_name = str(ch.get("enemy_name", enemy_name))
	var base_hp: int = int(ch.get("enemy_hp", enemy_hp_max))
	enemy_hp_max = GameState.scale_enemy_hp(base_hp)
	enemy_hp = enemy_hp_max
	chapter_xp_reward = int(ch.get("xp", 0))

# -----------------------------
# Battle loop
# -----------------------------
func _start_battle() -> void:
	state = BattleState.PLAYER_TURN
	battle_over = false
	guarded = false

	oath_points = 0
	oath_charges = 0
	potions = 3
	grace_points = 0

	boon_turns[Boon.WRATH] = 0
	boon_turns[Boon.AEGIS] = 0
	boon_turns[Boon.REGEN] = 0

	_log("[b]The war does not begin. It continues.[/b]")
	_roll_enemy_intent()
	_set_input_enabled(true)

func _begin_player_turn() -> void:
	state = BattleState.PLAYER_TURN
	guarded = false # Guard protects only against the next enemy attack

	_tick_boons_start_of_player_turn()
	_roll_enemy_intent()

	_set_input_enabled(true)
	_refresh_ui()

func _begin_enemy_turn() -> void:
	state = BattleState.ENEMY_TURN
	_set_input_enabled(false)
	_refresh_ui()
	await get_tree().create_timer(0.25).timeout

	_enemy_attack()
	_check_end_conditions()
	if battle_over:
		return

	await get_tree().create_timer(0.25).timeout
	_begin_player_turn()

# -----------------------------
# Player actions
# -----------------------------
func _on_strike() -> void:
	if state != BattleState.PLAYER_TURN or battle_over or oath_prompt_open:
		return
	var dmg := _calc_strike_damage()
	_apply_damage_to_enemy(dmg, "Tigris strikes with drilled precision.")
	_check_end_conditions()
	if battle_over:
		return
	await _begin_enemy_turn()

func _on_guard() -> void:
	if state != BattleState.PLAYER_TURN or battle_over or oath_prompt_open:
		return
	guarded = true
	_log("Shield raised. Breath steady. [i]The line holds.[/i]")
	await _begin_enemy_turn()

func _on_oath() -> void:
	if state != BattleState.PLAYER_TURN or battle_over or oath_prompt_open:
		return
	if oath_charges <= 0:
		_log("No oathbound strength gathered yet.")
		return

	# If 2+ charges, open micro prompt
	if oath_charges >= 2:
		_open_oath_prompt()
		return

	# Otherwise spend 1 immediately
	await _execute_oath_strike(1)

func _on_potion() -> void:
	if state != BattleState.PLAYER_TURN or battle_over or oath_prompt_open:
		return
	if potions <= 0:
		_log("No blessed potions remain.")
		return

	potions -= 1
	var heal := _calc_potion_heal()
	_apply_heal_to_player(heal, "Blessed draught. The ache recedes.")
	await _begin_enemy_turn()

func _on_pray() -> void:
	if state != BattleState.PLAYER_TURN or battle_over or oath_prompt_open:
		return

	# 10% fail chance
	if randf() < 0.10:
		_log("[i]Nyra’s presence was not felt…[/i]")
		await _begin_enemy_turn()
		return

	# Random boon (stackable but not same kind; refresh duration)
	var roll := randi_range(0, 2)
	var boon := Boon.WRATH if roll == 0 else (Boon.REGEN if roll == 1 else Boon.AEGIS)

	boon_turns[boon] = 3

	match boon:
		Boon.WRATH:
			_log("[b]A thought like dawn.[/b] Your arms feel weightless. ([i]Wrath[/i], 3 turns)")
		Boon.REGEN:
			_log("A gentle voice within: [i]Endure.[/i] ([i]Pale Regen[/i], 3 turns)")
		Boon.AEGIS:
			_log("A hush falls over pain itself. ([i]Aegis[/i], 3 turns)")

	await _begin_enemy_turn()

# -----------------------------
# Oath prompt
# -----------------------------
func _open_oath_prompt() -> void:
	oath_prompt_open = true
	oath_prompt.visible = true
	_set_input_enabled(false)

	spend1_button.disabled = oath_charges < 1
	spend2_button.disabled = oath_charges < 2

	_refresh_ui()

func _close_oath_prompt() -> void:
	oath_prompt_open = false
	oath_prompt.visible = false
	_refresh_ui()

func _confirm_oath_spend(spend: int) -> void:
	if battle_over or state != BattleState.PLAYER_TURN:
		_close_oath_prompt()
		return

	# Clamp to available charges (1 or 2)
	spend = clamp(spend, 1, min(2, oath_charges))

	_close_oath_prompt()
	# Fire and return control to normal flow
	_execute_oath_strike(spend)

func _execute_oath_strike(spend: int) -> void:
	oath_charges -= spend

	var base := _calc_strike_damage()
	var bonus_mult := 1.15 if spend == 1 else 1.35

	# Perk oath damage: +3% per rank
	bonus_mult *= (1.0 + 0.03 * float(perk_oath_dmg))

	var dmg := int(round(float(base) * bonus_mult))
	_apply_damage_to_enemy(dmg, "By the Stormguard’s oath—[b]VANQUISH[/b].")

	_check_end_conditions()
	if battle_over:
		return

	await _begin_enemy_turn()

# -----------------------------
# Intent + damage/heal calculations
# -----------------------------
func _roll_enemy_intent() -> void:
	# Weighted: more LIGHT than HEAVY
	enemy_intent = Intent.HEAVY if randf() < 0.35 else Intent.LIGHT

func _calc_strike_damage() -> int:
	# Strike base = 20% max hp, variance 25%
	var base := int(round(float(player_hp_max) * 0.20))
	var var_amt := int(round(float(base) * 0.25))
	var dmg := randi_range(max(1, base - var_amt), base + var_amt)

	# Perk strike damage: +0.5% per rank
	var mult := 1.0 + 0.005 * float(perk_strike_dmg)

	# Wrath doubles outgoing damage
	if boon_turns[Boon.WRATH] > 0:
		mult *= 2.0

	return int(round(float(dmg) * mult))

func _calc_enemy_damage() -> int:
	# Base damage scales off player max hp
	var base := 0
	if enemy_intent == Intent.LIGHT:
		base = int(round(float(player_hp_max) * randf_range(0.12, 0.18)))
	else:
		base = int(round(float(player_hp_max) * randf_range(0.20, 0.28)))

	# Guard halves next incoming hit
	if guarded:
		base = int(round(float(base) * 0.5))

	var mult := 1.0

	# Aegis halves incoming damage
	if boon_turns[Boon.AEGIS] > 0:
		mult *= 0.5

	# Perk def reduces damage 1% per rank (floor clamp)
	mult *= (1.0 - 0.01 * float(perk_def))
	mult = max(0.25, mult)

	return int(round(float(base) * mult))

func _calc_potion_heal() -> int:
	# 50–57% of max hp
	var pct := randf_range(0.50, 0.57)
	# Potion heal perk: +1% absolute per rank
	pct += 0.01 * float(perk_potion_heal)
	return int(round(float(player_hp_max) * pct))

func _apply_damage_to_enemy(dmg: int, flavor: String) -> void:
	enemy_hp = max(enemy_hp - dmg, 0)
	_log("%s [b]%s[/b] takes %d damage. (%d/%d)" % [flavor, enemy_name, dmg, enemy_hp, enemy_hp_max])

	# Oath points: damage dealt fills bar; threshold == max hp
	oath_points += dmg
	while oath_points >= _oath_threshold() and oath_charges < OATH_CHARGE_MAX:
		oath_points -= _oath_threshold()
		oath_charges += 1
		_log("[i]Oathbound strength gathers.[/i] (+1 charge)")

func _apply_heal_to_player(amt: int, flavor: String) -> void:
	player_hp = min(player_hp + amt, player_hp_max)
	_log("%s You recover %d HP. (%d/%d)" % [flavor, amt, player_hp, player_hp_max])

# -----------------------------
# Enemy attack + grace system
# -----------------------------
func _enemy_attack() -> void:
	if battle_over:
		return

	var intent_text := "LIGHT" if enemy_intent == Intent.LIGHT else "HEAVY"
	var dmg := _calc_enemy_damage()

	player_hp = max(player_hp - dmg, 0)
	_log("%s attack! You take %d damage. (%d/%d)" % [intent_text, dmg, player_hp, player_hp_max])

	# Grace points: damage taken fills bar; threshold ~80% max hp
	grace_points += dmg
	var threshold := _grace_threshold()
	if grace_points >= threshold:
		grace_points = 0
		potions += 1
		_log("[i]An angelic voice imprints to your mind: May this aid your fight.[/i] (+1 Blessed Potion)")

# -----------------------------
# Boons tick
# -----------------------------
func _tick_boons_start_of_player_turn() -> void:
	# Innate regen perk: heals 0.5% max hp per rank each player turn (min 1 if rank > 0)
	if GameState.perk_innate_regen > 0:
		var pct := 0.005 * float(GameState.perk_innate_regen)  # 0.5% per rank
		var heal := int(round(float(player_hp_max) * pct))
		heal = max(1, heal)
		if player_hp < player_hp_max:
			player_hp = min(player_hp + heal, player_hp_max)
			_log("Innate Regen restores %d HP. (%d/%d)" % [heal, player_hp, player_hp_max])

	# Regen heals 5% max hp at start of player turn
	if boon_turns[Boon.REGEN] > 0:
		var heal := int(round(float(player_hp_max) * 0.05))
		player_hp = min(player_hp + heal, player_hp_max)
		_log("Pale Regen restores %d HP. (%d/%d)" % [heal, player_hp, player_hp_max])

	# Decrement all boons
	for k in boon_turns.keys():
		if boon_turns[k] > 0:
			boon_turns[k] -= 1

# -----------------------------
# End conditions + UI
# -----------------------------
func _check_end_conditions() -> void:
	if enemy_hp <= 0:
		battle_over = true
		state = BattleState.BATTLE_OVER
		_log("[b]Victory.[/b] Another enemy falls. The war remains.")
		_set_input_enabled(false)
		oath_prompt.visible = false
		oath_prompt_open = false
		emit_signal("battle_finished", true)
		return

	if player_hp <= 0:
		battle_over = true
		state = BattleState.BATTLE_OVER
		_log("[b]Defeat…[/b] The line breaks—and history bleeds forward.")
		_set_input_enabled(false)
		oath_prompt.visible = false
		oath_prompt_open = false
		emit_signal("battle_finished", false)
		return

func _set_input_enabled(enabled: bool) -> void:
	# Base gating
	strike_button.disabled = not enabled
	guard_button.disabled = not enabled
	oath_button.disabled = not enabled
	potion_button.disabled = not enabled
	pray_button.disabled = not enabled

func _refresh_ui() -> void:
	# HP bars
	player_top_bar.max_value = player_hp_max
	player_top_bar.value = player_hp

	enemy_top_bar.max_value = enemy_hp_max
	enemy_top_bar.value = enemy_hp

	enemy_name_label.text = enemy_name

	# Intent label visible during player turn
	if state == BattleState.PLAYER_TURN and not battle_over:
		intent_label.text = "Intent: " + ("LIGHT" if enemy_intent == Intent.LIGHT else "HEAVY")
	else:
		intent_label.text = ""

	# Oath UI
	oath_bar.max_value = _oath_threshold()
	oath_bar.value = oath_points
	oath_charges_label.text = "Oath: %d/%d" % [oath_charges, OATH_CHARGE_MAX]

	# Grace UI (bar only; no numeric)
	grace_bar.max_value = _grace_threshold()
	grace_bar.value = grace_points
	potions_label.text = "Potions: %d" % potions

	# Action gating
	var can_act := (state == BattleState.PLAYER_TURN) and (not battle_over) and (not oath_prompt_open)
	strike_button.disabled = not can_act
	guard_button.disabled = not can_act
	pray_button.disabled = not can_act

	oath_button.disabled = (not can_act) or (oath_charges <= 0)
	potion_button.disabled = (not can_act) or (potions <= 0)

	# Prompt button gating if prompt is open
	if oath_prompt_open:
		spend1_button.disabled = oath_charges < 1
		spend2_button.disabled = oath_charges < 2

func _on_battle_finished(victory: bool) -> void:
	# Small delay so the final log line feels readable
	await get_tree().create_timer(0.35).timeout

	var fought_index := GameState.selected_battle_index
	var was_current := (fought_index == GameState.campaign_index)

	if victory:
		# Reward XP always (including replays)
		var scaled_xp: int = GameState.scale_xp_reward(int(chapter_xp_reward))
		var leveled := GameState.add_xp(scaled_xp)

		# Mark completion only if it was the current chapter
		if was_current:
			GameState.completed[fought_index] = true

			# Advance campaign if not final chapter
			if GameState.campaign_index < 8:
				GameState.campaign_index += 1

		# Milestone narrative: after completing a current chapter (2, 5, 9)
		var next_scene := "res://war_table.tscn"
		if leveled or GameState.spec_points_unspent > 0:
			next_scene = "res://perk_menu.tscn"

		# Only fire milestone narratives when the player cleared the current chapter
		if was_current:
			var completed_chapter_num := fought_index + 1  # fought_index is 0-based
			if completed_chapter_num == 9:
				next_scene = "res://war_table.tscn"  # you’ll create this scene
			print("MILestone check:",
				" was_current=", was_current,
				" fought_index=", fought_index,
				" completed_chapter_num=", completed_chapter_num,
				" seen=", GameState.has_seen_narrative(GameState.NARR_AFTER_CHAPTER.get(completed_chapter_num, "")),
				" seq_size=", NarrativeDB.get_sequence(GameState.NARR_AFTER_CHAPTER.get(completed_chapter_num, "")).size()
			)

			if GameState.maybe_start_narrative_after_chapter(completed_chapter_num, next_scene):
				return

		# Existing routing
		if leveled or GameState.spec_points_unspent > 0:
			get_tree().change_scene_to_file("res://perk_menu.tscn")
		else:
			get_tree().change_scene_to_file("res://war_table.tscn")
		return

	# Defeat:
	if GameState.can_revive():
		GameState.lose_life()
		if GameState.lives <= 0:
			get_tree().change_scene_to_file("res://game_over.tscn")
		else:
			get_tree().change_scene_to_file("res://war_table.tscn")
		return

	# Final battle defeat (no revival)
	get_tree().change_scene_to_file("res://game_over.tscn")

func _log(t: String) -> void:
	# Newest on top
	log_lines.insert(0, t)

	# Trim old lines
	if log_lines.size() > LOG_MAX_LINES:
		log_lines.resize(LOG_MAX_LINES)

	# Rebuild the label
	log_label.clear()
	log_label.append_text("\n".join(log_lines) + "\n")

	_refresh_ui()
