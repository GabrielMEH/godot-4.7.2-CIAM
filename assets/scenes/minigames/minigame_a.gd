class_name TrashMinigame
extends Node2D

# Nós de áudio esperados (filhos diretos da raiz, com o stream já atribuído):
#   PickupSound  -> som de pegar o cigarro
#   FailSound    -> som de tempo esgotado
# Se algum nó não existir ou não tiver stream, o minigame simplesmente fica sem aquele som.

signal minigame_finished(success: bool, time_delta: int)

const BACKGROUND_GROW_TIME := 0.15
const FADE_IN_TIME := 0.1

@export var time_limit: float = 10.0
@export var success_time_bonus: int = 15
@export var failure_time_penalty: int = 10

@onready var timer: Timer = $TimeLimit
@onready var trash_can: Area2D = $TrashCan
@onready var trash: RigidBody2D = $Trash
@onready var timer_label: Label = $TimerLabel
@onready var background: NinePatchRect = $background

@onready var pickup_sound: AudioStreamPlayer = get_node_or_null("PickupSound")
@onready var fail_sound: AudioStreamPlayer = get_node_or_null("FailSound")

var time_left: float = 0.0
var finished: bool = false


func _ready() -> void:
	position = get_viewport_rect().size / 2
	time_left = time_limit

	timer.wait_time = time_limit
	timer.one_shot = true
	timer.timeout.connect(_on_time_up)

	trash_can.trash_delivered.connect(_on_trash_delivered)
	trash.input_event.connect(_on_trash_input_event)

	_play_intro_animation()
	timer.start()


func _process(delta: float) -> void:
	if finished:
		return
	time_left = max(time_left - delta, 0.0)
	timer_label.text = "%.1f" % time_left


# --- Eventos -------------------------------------------------------------------

func _on_trash_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if finished:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
		_play_sound(pickup_sound, randf_range(0.95, 1.05))


func _on_trash_delivered() -> void:
	if finished:
		return
	_finish(true)


func _on_time_up() -> void:
	if finished:
		return
	_finish(false)


# --- Fim do minigame -----------------------------------------------------------

func _finish(success: bool) -> void:
	finished = true
	timer.stop()
	if not success:
		_play_sound(fail_sound)
	minigame_finished.emit(success, success_time_bonus if success else failure_time_penalty)


# --- Animação e efeitos --------------------------------------------------------

func _play_intro_animation() -> void:
	trash.modulate.a = 0.0
	trash_can.modulate.a = 0.0
	timer_label.modulate.a = 0.0

	var final_size := background.size
	background.size = Vector2.ZERO

	var tween := create_tween()
	# 1. Fundo cresce
	tween.tween_property(background, "size", final_size, BACKGROUND_GROW_TIME)
	# 2. Tudo aparece junto, rápido
	tween.tween_property(trash, "modulate:a", 1.0, FADE_IN_TIME)
	tween.parallel().tween_property(trash_can, "modulate:a", 1.0, FADE_IN_TIME)
	tween.parallel().tween_property(timer_label, "modulate:a", 1.0, FADE_IN_TIME)


func _play_sound(player: AudioStreamPlayer, pitch: float = 1.0) -> void:
	if player == null or player.stream == null:
		return
	player.pitch_scale = pitch
	player.play()
