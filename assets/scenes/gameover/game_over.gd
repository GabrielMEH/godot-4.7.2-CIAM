# game_over.gd
extends CanvasLayer

const BACKGROUND_FADE_TIME := 1.5
const IMAGE_FADE_TIME := 0.8
const BUTTONS_FADE_TIME := 0.6
const DELAY_BETWEEN_STEPS := 0.2

@onready var retry_button: Button = $VBoxContainer/VBoxContainer/RetryButton
@onready var menu_button: Button = $VBoxContainer/VBoxContainer/MenuButton
@onready var buttons_container: VBoxContainer = $VBoxContainer/VBoxContainer
@onready var game_over_imagem: TextureRect = $VBoxContainer/gameOverImage
@onready var background: ColorRect = $background


func _ready() -> void:
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	_play_intro_animation()


func _play_intro_animation() -> void:
	background.modulate.a = 0.0
	game_over_imagem.modulate.a = 0.0
	buttons_container.modulate.a = 0.0
	_set_buttons_enabled(false)

	var tween := create_tween()
	tween.tween_property(background, "modulate:a", 1.0, BACKGROUND_FADE_TIME)
	tween.tween_interval(DELAY_BETWEEN_STEPS)
	tween.tween_property(game_over_imagem, "modulate:a", 1.0, IMAGE_FADE_TIME)
	tween.tween_interval(DELAY_BETWEEN_STEPS)
	tween.tween_property(buttons_container, "modulate:a", 1.0, BUTTONS_FADE_TIME)
	tween.tween_callback(_on_intro_finished)


func _on_intro_finished() -> void:
	_set_buttons_enabled(true)
	retry_button.grab_focus() # permite navegar com teclado/controle


func _set_buttons_enabled(enabled: bool) -> void:
	retry_button.disabled = not enabled
	menu_button.disabled = not enabled


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://assets/scenes/main_menu/main_menu.tscn")
