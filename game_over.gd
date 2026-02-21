extends Control

@onready var continue_btn: Button = $Root/Buttons/ContinueButton
@onready var quit_btn: Button = $Root/Buttons/QuitButton

func _ready() -> void:
	Presentation.set_background(
		load("res://assets/backgrounds/menus/game_over.png"),
		Presentation.Context.GAME_OVER
	)
	continue_btn.pressed.connect(_on_continue)
	quit_btn.pressed.connect(func(): get_tree().quit())

func _on_continue() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file("res://war_table.tscn")
