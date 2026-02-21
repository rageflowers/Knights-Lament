class_name BattleActor
extends Node2D

@onready var art: Sprite2D = $ArtRoot/Art
@onready var hit_point: Marker2D = $HitPoint

const ENEMY_ANCHOR_PX := Vector2(235, 205)
const ENEMY_HITPOINT_PX := Vector2(192, 180)

func apply_enemy(enemy_data: Dictionary) -> void:
	var path := _enemy_path_from_data(enemy_data)
	var tex := load(path) as Texture2D
	if tex == null:
		push_warning("Enemy sprite not found: %s" % path)
		return

	# Safety: make sure nothing is accidentally transparent
	visible = true
	self_modulate = Color(1, 1, 1, 1)
	modulate = Color(1, 1, 1, 1)

	art.texture = tex
	art.visible = true
	art.modulate = Color(1, 1, 1, 1)
	art.region_enabled = false

	# Anchor mode (bottom-center ground line for 384x384)
	art.centered = false
	art.position = -ENEMY_ANCHOR_PX

	# Hitpoint (relative to anchor)
	hit_point.position = ENEMY_HITPOINT_PX - ENEMY_ANCHOR_PX
# Nyra approves this enemy path logic~
func _enemy_path_from_data(enemy_data: Dictionary) -> String:
	var id: int = int(enemy_data.get("id", -1))
	var enemy_name: String = str(enemy_data.get("enemy_name", ""))
	var slug := _slugify(enemy_name)

	var candidate := "res://assets/sprites/enemies/enemy_%02d_%s.png" % [id, slug]
	if ResourceLoader.exists(candidate):
		return candidate

	# Fallback: id only if you ever choose to simplify names later
	return "res://assets/sprites/enemies/enemy_%02d.png" % id


func _slugify(s: String) -> String:
	s = s.to_lower()

	var out := ""
	var prev_underscore := false
	for i in s.length():
		var c := s[i]
		var is_alnum := (c >= "a" and c <= "z") or (c >= "0" and c <= "9")

		if is_alnum:
			out += c
			prev_underscore = false
		else:
			if not prev_underscore:
				out += "_"
				prev_underscore = true

	# trim underscores
	while out.begins_with("_"):
		out = out.substr(1)
	while out.ends_with("_"):
		out = out.substr(0, out.length() - 1)

	return out
