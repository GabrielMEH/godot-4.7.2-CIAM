class_name FireCallMinigame
extends Node2D

# Nós de áudio esperados (filhos diretos da raiz, com o stream já atribuído):
#   KeySound     -> som de tecla
#   WrongSound   -> som de número errado
#   RingingSound -> som de "chamando"
# Se algum nó não existir ou não tiver stream, o minigame simplesmente fica sem aquele som.

signal minigame_finished(success: bool, time_delta: int)

const MAX_DIGITS := 3
const CELLPHONE_FADE_TIME := 0.6
const CELLPHONE_START_SCALE := 0.85
const RINGING_DURATION := 2.0

const COLOR_ERROR := Color(1.0, 0.3, 0.3)
const COLOR_SUCCESS := Color(0.4, 1.0, 0.4)

@export var time_limit: float = 10.0
@export var emergency_number: String = "193"
@export var success_time_bonus: int = 15
@export var failure_time_penalty: int = 10

@onready var timer: Timer = $TimeLimit
@onready var timer_label: Label = $TimerLabel
@onready var display_label: Label = $Cellphone/DisplayLabel
@onready var keypad: GridContainer = $Cellphone/Keypad
@onready var delete_button: Button = $Cellphone/Keypad/ButtonDel
@onready var call_button: Button = $Cellphone/Keypad/ButtonCall
@onready var background: NinePatchRect = $background
@onready var cellphone: Sprite2D = $Cellphone

@onready var key_sound: AudioStreamPlayer = get_node_or_null("KeySound")
@onready var wrong_sound: AudioStreamPlayer = get_node_or_null("WrongSound")
@onready var ringing_sound: AudioStreamPlayer = get_node_or_null("RingingSound")

var time_left: float = 0.0
var finished: bool = false
var dialed_number: String = ""
var display_origin: Vector2
var cellphone_base_scale: Vector2
var punch_tweens: Dictionary = {}  # Control -> Tween, evita tweens brigando pelo mesmo nó


func _ready() -> void:
	position = get_viewport_rect().size / 2
	display_origin = display_label.position
	cellphone_base_scale = cellphone.scale
	time_left = time_limit

	timer.wait_time = time_limit
	timer.one_shot = true
	timer.timeout.connect(_on_time_up)

	_connect_keypad()
	_update_display()
	_play_intro_animation()
	timer.start()


func _process(delta: float) -> void:
	if finished:
		return
	time_left = max(time_left - delta, 0.0)
	timer_label.text = "%.1f" % time_left


# --- Teclado -----------------------------------------------------------------

func _connect_keypad() -> void:
	for child in keypad.get_children():
		var button := child as Button
		if button == null or button == delete_button or button == call_button:
			continue
		if button.text.is_valid_int():
			# button_down responde na hora, sem esperar o jogador soltar o botão
			button.button_down.connect(_on_digit_pressed.bind(button.text, button))
	delete_button.button_down.connect(_on_delete_pressed)
	call_button.button_down.connect(_on_call_pressed)


func _on_digit_pressed(digit: String, button: Button) -> void:
	if finished or dialed_number.length() >= MAX_DIGITS:
		return
	dialed_number += digit
	_update_display()

	_punch_scale(button, 0.9)          # tecla afunda
	_punch_scale(display_label, 1.2)   # visor reage ao novo dígito
	# Tom sobe a cada dígito, com uma variaçãozinha para não cansar
	_play_sound(key_sound, 1.0 + 0.06 * dialed_number.length() + randf_range(-0.02, 0.02))


func _on_delete_pressed() -> void:
	if finished:
		return
	dialed_number = dialed_number.left(-1)
	_update_display()

	_punch_scale(delete_button, 0.9)
	_punch_scale(display_label, 1.1)
	_play_sound(key_sound, 0.85)


func _on_call_pressed() -> void:
	if finished:
		return
	_punch_scale(call_button, 0.9)
	if dialed_number == emergency_number:
		_finish(true)
	else:
		_on_wrong_number()


func _on_wrong_number() -> void:
	dialed_number = ""
	_update_display()
	_play_sound(wrong_sound)

	# Tremida no visor
	var shake := create_tween()
	for i in 3:
		shake.tween_property(display_label, "position:x", display_origin.x + 8.0, 0.04)
		shake.tween_property(display_label, "position:x", display_origin.x - 8.0, 0.04)
	shake.tween_property(display_label, "position:x", display_origin.x, 0.04)

	# Flash vermelho (self_modulate não conflita com o fade da intro, que usa modulate)
	display_label.self_modulate = COLOR_ERROR
	create_tween().tween_property(display_label, "self_modulate", Color.WHITE, 0.3)


func _update_display() -> void:
	display_label.text = dialed_number if not dialed_number.is_empty() else "_"


# --- Fim do minigame -----------------------------------------------------------

func _on_time_up() -> void:
	if finished:
		return
	_finish(false)


func _finish(success: bool) -> void:
	finished = true
	timer.stop()
	for child in keypad.get_children():
		var button := child as Button
		if button:
			button.disabled = true

	if success:
		display_label.text = "Chamando..."
		display_label.self_modulate = COLOR_SUCCESS
		_play_sound(ringing_sound)
		await get_tree().create_timer(RINGING_DURATION).timeout

	minigame_finished.emit(success, success_time_bonus if success else failure_time_penalty)


# --- Animações e efeitos -------------------------------------------------------

func _play_intro_animation() -> void:
	display_label.modulate.a = 0.0
	keypad.modulate.a = 0.0
	timer_label.modulate.a = 0.0
	cellphone.modulate.a = 0.0
	cellphone.scale = cellphone_base_scale * CELLPHONE_START_SCALE

	var final_size := background.size
	background.size = Vector2.ZERO

	var tween := create_tween()
	# 1. Fundo cresce
	tween.tween_property(background, "size", final_size, 0.2)
	tween.tween_interval(0.2)
	# 2. Celular aparece devagar, com "pop" de mola
	tween.tween_property(cellphone, "modulate:a", 1.0, CELLPHONE_FADE_TIME)
	tween.parallel().tween_property(cellphone, "scale", cellphone_base_scale, CELLPHONE_FADE_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 3. Visor, teclado e timer aparecem juntos
	tween.tween_property(display_label, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(keypad, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(timer_label, "modulate:a", 1.0, 0.2)


func _punch_scale(control: Control, amount: float = 1.15, duration: float = 0.12) -> void:
	# Se já existe um punch rodando nesse controle, cancela para não acumular
	if punch_tweens.has(control):
		var old_tween: Tween = punch_tweens[control]
		if old_tween and old_tween.is_valid():
			old_tween.kill()

	control.pivot_offset = control.size / 2.0
	var tween := create_tween()
	punch_tweens[control] = tween
	tween.tween_property(control, "scale", Vector2.ONE * amount, duration * 0.4) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, duration * 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_sound(player: AudioStreamPlayer, pitch: float = 1.0) -> void:
	if player == null or player.stream == null:
		return
	player.pitch_scale = pitch
	player.play()
