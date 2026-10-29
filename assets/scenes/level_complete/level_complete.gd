class_name LevelCompleteScreen
extends CanvasLayer

const SCORE_COUNT_TIME := 1.0

@onready var time_bonus_label: Label = $VBoxContainer/TimeBonusLabel
@onready var penalty_label: Label = $VBoxContainer/PenaltyLabel
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var retry_button: Button = $VBoxContainer/Buttons/RetryButton
@onready var menu_button: Button = $VBoxContainer/Buttons/MenuButton


func _ready() -> void:
	# o jogo fica pausado enquanto a tela está aberta, então a UI precisa rodar mesmo assim
	process_mode = Node.PROCESS_MODE_ALWAYS
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)


# chamado pelo Level logo depois do add_child
func setup(time_bonus: int, penalty: int, final_score: int) -> void:
	time_bonus_label.text = "Bônus de tempo: +%d" % time_bonus
	penalty_label.text = "Penalidade por erros: -%d" % penalty
	score_label.text = "Pontuação: 0"

	# pontuação sobe contando até o valor final
	var tween := create_tween()
	tween.tween_method(_set_score_text, 0.0, float(final_score), SCORE_COUNT_TIME)


func _set_score_text(value: float) -> void:
	score_label.text = "Pontuação: %d" % int(value)


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://assets/scenes/main_menu/main_menu.tscn")
