extends Node

const PRESENTATION_LAYER_SCENE := preload("res://scenes/presentation_layer.tscn")

enum Context {
	BATTLE,
	NARRATIVE,
	START_MENU,
	SAVE_MENU,
	GAME_OVER,
	PERK_MENU,
	WAR_TABLE
}

var _layer: CanvasLayer = null
var _bg: Sprite2D = null

var _last_context: int = Context.WAR_TABLE
var _pending_texture: Texture2D = null
var _pending_context: int = Context.WAR_TABLE


func _ready() -> void:
	# Instance once and attach to SceneTree root so it persists across scene changes.
	_layer = PRESENTATION_LAYER_SCENE.instantiate() as CanvasLayer
	_layer.name = "PresentationLayer"
	get_tree().root.add_child.call_deferred(_layer)
	call_deferred("_after_added")


func _after_added() -> void:
	_bind_nodes()

	# react to window/viewport changes
	get_viewport().size_changed.connect(_on_viewport_resized)

	# If someone called set_background before we were ready, apply now.
	if _pending_texture != null:
		_apply_background(_pending_texture, _pending_context)
		_pending_texture = null


func _bind_nodes() -> void:
	# In presentation_layer.tscn, BG must be a Sprite2D named "BG"
	_bg = _layer.get_node_or_null("BG") as Sprite2D
	if _bg == null:
		push_error("[PRESENTATION] Missing node 'BG' (Sprite2D) in presentation_layer.tscn")
		return

	# Normalize base state (prevents “bad vibes” from old inspector settings)
	_bg.centered = true
	_bg.offset = Vector2.ZERO
	_bg.rotation = 0.0
	_bg.skew = 0.0
	_bg.scale = Vector2.ONE
	_bg.position = Vector2.ZERO
	_bg.modulate = Color(1, 1, 1, 1)
	_bg.self_modulate = Color(1, 1, 1, 1)
	_bg.visible = true
	_bg.z_index = -100


func set_background(texture: Texture2D, context: int) -> void:
	_last_context = context

	# If BG isn't bound yet, queue the request.
	if _bg == null:
		_pending_texture = texture
		_pending_context = context
		return

	_apply_background(texture, context)

func set_bg_alpha(a: float) -> void:
	# Safe: does nothing if PresentationLayer/BG isn’t ready yet.
	if _bg == null:
		return

	var alpha: float = clampf(a, 0.0, 1.0)

	var c: Color = _bg.modulate
	c.a = alpha
	_bg.modulate = c

	var sc: Color = _bg.self_modulate
	sc.a = alpha
	_bg.self_modulate = sc

func clear_background() -> void:
	if _bg == null:
		_pending_texture = null
		return
	_bg.texture = null


func _apply_background(texture: Texture2D, _context: int) -> void:
	if _bg == null:
		return

	_bg.texture = texture

	# If texture is null, that's effectively "clear".
	if texture == null:
		return

	# Hard reset (again) right before applying scaling/positioning.
	_bg.centered = true
	_bg.offset = Vector2.ZERO
	_bg.modulate = Color(1, 1, 1, 1)
	_bg.self_modulate = Color(1, 1, 1, 1)

	_on_viewport_resized() # positions + scales using last context


func _on_viewport_resized() -> void:
	if _bg == null or _bg.texture == null:
		return

	var vp := get_viewport().get_visible_rect().size
	var tex_size := _bg.texture.get_size()

	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return

	# Always center the sprite in the viewport
	_bg.position = vp * 0.5

	var sx := vp.x / tex_size.x
	var sy := vp.y / tex_size.y

	# BATTLE = COVER (crop allowed), everything else = CONTAIN (no crop)
	var s: float
	if _last_context == Context.BATTLE:
		s = max(sx, sy)
	else:
		s = min(sx, sy)

	_bg.scale = Vector2(s, s)

	# Debug (optional)
	# print("[PRESENTATION] ctx=", _last_context, " vp=", vp, " tex=", tex_size, " sx=", sx, " sy=", sy, " chosen=", s)
