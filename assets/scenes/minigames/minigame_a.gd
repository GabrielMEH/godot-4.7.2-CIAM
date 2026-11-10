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
@onready var all_trash: Array[RigidBody2D] = [$Trash, $Trash2, $Trash3, $Trash4]
var active_trash: Array[RigidBody2D] = []
var delivered_trash: Array[RigidBody2D] = []
@onready var timer_bar: TextureProgressBar = $MinigameTimer
@onready var timer_label: Label = $MinigameTimer/TimerLabel
@onready var background: NinePatchRect = $background

@onready var pickup_sound: AudioStreamPlayer = get_node_or_null("PickupSound")
@onready var fail_sound: AudioStreamPlayer = get_node_or_null("FailSound")

var time_left: float = 0.0
var finished: bool = false

func _ready() -> void:
	position = get_viewport_rect().size / 2
	time_left = time_limit
	timer_bar.max_value = time_limit
	timer_bar.value = time_limit

	timer.wait_time = time_limit
	timer.one_shot = true
	timer.timeout.connect(_on_time_up)

	_setup_trash()
	# antes: trash_can.trash_delivered.connect(_on_trash_delivered)
	trash_can.body_entered.connect(_on_trash_can_body_entered)

	_play_intro_animation()
	timer.start()

func _process(delta: float) -> void:
	if finished:
		return
	time_left = max(time_left - delta, 0.0)
	timer_label.text = "%d" % int(time_left)
	timer_bar.value = time_left


# --- Eventos -------------------------------------------------------------------

func _on_trash_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if finished:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event and mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
		_play_sound(pickup_sound, randf_range(0.95, 1.05))


func _on_trash_can_body_entered(body: Node2D) -> void:
	if finished:
		return
	var piece := body as RigidBody2D
	if piece == null or not active_trash.has(piece) or delivered_trash.has(piece):
		return

	delivered_trash.append(piece)
	_deactivate_trash(piece)

	if delivered_trash.size() >= active_trash.size():
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
	for piece in active_trash:
		piece.modulate.a = 0.0
	trash_can.modulate.a = 0.0
	timer_bar.modulate.a = 0.0

	var final_size := background.size
	background.size = Vector2.ZERO

	var tween := create_tween()
	# 1. Fundo cresce
	tween.tween_property(background, "size", final_size, BACKGROUND_GROW_TIME)
	# 2. Tudo aparece junto, rápido
	tween.tween_property(trash_can, "modulate:a", 1.0, FADE_IN_TIME)
	tween.parallel().tween_property(timer_bar, "modulate:a", 1.0, FADE_IN_TIME)
	for piece in active_trash:
		tween.parallel().tween_property(piece, "modulate:a", 1.0, FADE_IN_TIME)


func _play_sound(player: AudioStreamPlayer, pitch: float = 1.0) -> void:
	if player == null or player.stream == null:
		return
	player.pitch_scale = pitch
	player.play()

func _setup_trash() -> void:
	var shuffled := all_trash.duplicate()
	shuffled.shuffle()
	var amount := randi_range(1, all_trash.size())

	for i in shuffled.size():
		var piece: RigidBody2D = shuffled[i]
		if i < amount:
			active_trash.append(piece)
			piece.input_event.connect(_on_trash_input_event)
		else:
			_disable_trash(piece)


func _disable_trash(piece: RigidBody2D) -> void:
	piece.visible = false
	piece.freeze = true
	piece.collision_layer = 0
	piece.collision_mask = 0
	piece.input_pickable = false

func _deactivate_trash(piece: RigidBody2D) -> void:
	# em callbacks de física, as mudanças de colisão precisam ser adiadas
	piece.set_deferred("freeze", true)
	piece.set_deferred("collision_layer", 0)
	piece.set_deferred("collision_mask", 0)
	piece.input_pickable = false

	# some com um encolhidinho em vez de desaparecer seco
	var tween := create_tween().set_parallel(true)
	tween.tween_property(piece, "scale", Vector2.ZERO, 0.15)
	tween.tween_property(piece, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(piece.hide)
