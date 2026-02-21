extends Control

const WAR_TABLE_SCENE: String = "res://war_table.tscn"

@onready var _points_label: Label = $"Root/HeaderRow/PointsLabel"
@onready var _hint: Label = $"Root/HeaderRow/Hint"
@onready var _back_btn: Button = $"Root/HeaderRow/BackButton"

@onready var _hp_btn: Button = $"Root/HeaderRow/Grid/HPButton"
@onready var _def_btn: Button = $"Root/HeaderRow/Grid/DefButton"
@onready var _potion_btn: Button = $"Root/HeaderRow/Grid/PotionButton"
@onready var _strike_btn: Button = $"Root/HeaderRow/Grid/StrikeButton"
@onready var _oath_btn: Button = $"Root/HeaderRow/Grid/OathButton"
@onready var _grace_btn: Button = $"Root/HeaderRow/Grid/GraceButton"
@onready var _regen_btn: Button = $"Root/HeaderRow/Grid/RegenButton"

const PERKS: Array[Dictionary] = [
	{"field":"perk_hp",           "label":"HP"},
	{"field":"perk_def",          "label":"DEF"},
	{"field":"perk_potion_heal",  "label":"Potion Heal"},
	{"field":"perk_strike_dmg",   "label":"Strike DMG"},
	{"field":"perk_oath_dmg",     "label":"Oath DMG"},
	{"field":"perk_grace",        "label":"Grace"},
	{"field":"perk_innate_regen", "label":"Regen"},
]

var _btn_for_field: Dictionary = {}

func _ready() -> void:
	_btn_for_field = {
		"perk_hp": _hp_btn,
		"perk_def": _def_btn,
		"perk_potion_heal": _potion_btn,
		"perk_strike_dmg": _strike_btn,
		"perk_oath_dmg": _oath_btn,
		"perk_grace": _grace_btn,
		"perk_innate_regen": _regen_btn,
	}

	for perk in PERKS:
		var field: String = String(perk["field"])
		var btn: Button = _btn_for_field[field]
		btn.pressed.connect(func(): _buy_perk(field))
		btn.focus_entered.connect(func(): _set_hint(field))
		btn.mouse_entered.connect(func(): _set_hint(field))

	_back_btn.pressed.connect(_go_back)

	_refresh_all()
	_set_hint("perk_hp")


func _go_back() -> void:
	get_tree().change_scene_to_file(WAR_TABLE_SCENE)


func _gs_int(field: String, default_value: int = 0) -> int:
	var v = GameState.get(field)
	if v == null:
		return default_value
	return int(v)


func _buy_perk(field: String) -> void:
	var points: int = int(GameState.spec_points_unspent)
	if points <= 0:
		return

	var rank: int = _gs_int(field, 0)
	# Cap Grace at the battle limit (50% threshold => 30 points from 80% down to 50%)
	if field == "perk_grace" and rank >= 30:
		return
	if field == "perk_def" and rank >= 75:
		return

	GameState.set(field, rank + 1)
	GameState.spec_points_unspent = points - 1

	_refresh_all()
	_set_hint(field)


func _refresh_all() -> void:
	_points_label.text = "Points: " + str(int(GameState.spec_points_unspent))
	_refresh_buttons()


func _refresh_buttons() -> void:
	var points: int = int(GameState.spec_points_unspent)

	const GRACE_CAP: int = 30
	const DEF_CAP: int = 75
	const UNCAPPED_STR: String = "∞"

	for perk in PERKS:
		var field: String = String(perk["field"])
		var label: String = String(perk["label"])
		var rank: int = _gs_int(field, 0)

		var btn: Button = _btn_for_field[field]

		var capped: bool = false
		var possible_str: String = UNCAPPED_STR

		if field == "perk_grace":
			possible_str = str(GRACE_CAP)
			capped = (rank >= GRACE_CAP)
		elif field == "perk_def":
			possible_str = str(DEF_CAP)
			capped = (rank >= DEF_CAP)

		btn.text = label + "   " + str(rank) + "/" + possible_str + ( " (MAX)" if capped else "" )

		# Disabled: no points, or capped perks (Grace/DEF)
		btn.disabled = (points <= 0) or capped

func _set_hint(field: String) -> void:
	var rank: int = _gs_int(field, 0)
	var next: int = rank + 1

	match field:
		"perk_hp":
			# Battle: +1% max HP per rank
			_hint.text = "HP — Increases Max HP by 1% per point. Current: +" + str(rank) + "%  Next: +" + str(next) + "%."

		"perk_def":
			var cur_reduction: int = min(75, rank)
			var nxt_reduction: int = min(75, next)

			_hint.text = "DEF — Take less damage from enemy attacks.\n" \
				+ "Current: ~" + str(cur_reduction) + "% less  •  Next: ~" + str(nxt_reduction) + "% less  (Max: 75%)"

		"perk_potion_heal":
			# Battle: potion heals 50–57% of Max HP, plus +1% absolute per rank
			var cur_min: int = 50 + rank
			var cur_max: int = 57 + rank
			var nxt_min: int = 50 + next
			var nxt_max: int = 57 + next
			_hint.text = "Potion Heal — Potions heal " + str(cur_min) + "–" + str(cur_max) + "% of Max HP. Next: " + str(nxt_min) + "–" + str(nxt_max) + "%."

		"perk_strike_dmg":
			# Battle: strike mult = 1 + 0.005*rank
			var cur_pct: float = 0.5 * float(rank)
			var nxt_pct: float = 0.5 * float(next)
			_hint.text = "Strike DMG — Strike damage +" + _fmt1(cur_pct) + "% (Current). Next: +" + _fmt1(nxt_pct) + "%."

		"perk_oath_dmg":
			# Battle: oath bonus mult *= (1 + 0.03*rank)
			var cur_pct: int = 3 * rank
			var nxt_pct: int = 3 * next
			_hint.text = "Oath DMG — Oath Strike bonus damage +" + str(cur_pct) + "% (Current). Next: +" + str(nxt_pct) + "%."

		"perk_grace":
			# Threshold ratio: starts at 80% of Max HP, drops 1% per point, capped at 50%.
			var cur_ratio: float = max(0.50, 0.80 - 0.01 * float(rank))
			var nxt_ratio: float = max(0.50, 0.80 - 0.01 * float(next))

			var cur_pct: int = int(round(cur_ratio * 100.0))
			var nxt_pct: int = int(round(nxt_ratio * 100.0))

			_hint.text = "Grace — Blessed Potion awarded when your Grace meter fills (damage taken).\n" \
				+ "Fill at: " + str(cur_pct) + "% of Max HP dmg  •  Next: " + str(nxt_pct) + "%  (Cap: 50%)"

		"perk_innate_regen":
			# Battle: heals 0.5% max HP per rank each player turn (min 1 if rank>0)
			var cur_pct: float = 0.5 * float(rank)
			var nxt_pct: float = 0.5 * float(next)
			var cur_note: String = " (min 1)" if rank > 0 else ""
			var nxt_note: String = " (min 1)"
			_hint.text = "Regen — Heals " + _fmt1(cur_pct) + "% Max HP each player turn" + cur_note + ". Next: " + _fmt1(nxt_pct) + "%" + nxt_note + "."

		_:
			_hint.text = ""


func _fmt2(v: float) -> String:
	return String.num(v, 2)

func _fmt1(v: float) -> String:
	return String.num(v, 1)
