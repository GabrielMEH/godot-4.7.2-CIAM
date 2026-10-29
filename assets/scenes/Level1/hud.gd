extends CanvasLayer

const DANGER_START_RATIO := 0.5
const DANGER_MAX_ALPHA := 1
const BLINK_SPEED_MIN := 3.0   # radianos por segundo (piscar lento)
const BLINK_SPEED_MAX := 10.0  # piscar rápido perto do fim
const BLINK_MIN_INTENSITY := 0.4  # o quanto o alpha cai no "vale" do pulso

@onready var time_limit_bar: TextureProgressBar = $time_limit_bar
@onready var level_progress_bar: TextureProgressBar = $level_progress_bar
@onready var counter_label: Label = $time_limit_bar/CounterLabel
@onready var danger_overlay: TextureRect = $Danger_overlay
@onready var positive_audio: AudioStreamPlayer = $PositiveAudio
@onready var positive_audio2: AudioStreamPlayer = $PositiveAudio2
@onready var negative_audio: AudioStreamPlayer = $NegativeAudio
@onready var floating_text: Label = $level_progress_bar/FloatingText

const FLOAT_TEXT_RISE := 40.0
const FLOAT_COLOR_GAIN := Color(0.55, 1.0, 0.35)
const FLOAT_COLOR_LOSS := Color(1.0, 0.35, 0.3)

var danger_level := 0.0  # 0 = seguro, 1 = tempo quase zerado
var blink_phase := 0.0

var last_progress := 0.0
var floating_text_base_y: float
var floating_text_tween: Tween


func _ready() -> void:
	danger_overlay.modulate.a = 0.0
	danger_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE # não bloqueia cliques

	var level = get_parent()  # Level1 nesse caso
	level.time_updated.connect(_on_time_updated)
	level.time_expired.connect(_on_time_expired)
	level.progress_updated.connect(_on_progress_updated)
	level.progress_finished.connect(_on_progress_completed)
	
	floating_text_base_y = floating_text.position.y
	floating_text.pivot_offset = floating_text.size / 2.0


func _process(delta: float) -> void:
	_process_danger(delta)


func _on_time_updated(time_left: float, max_time: float) -> void:
	time_limit_bar.max_value = max_time
	time_limit_bar.value = time_left
	counter_label.text = str(int(time_left))

	var time_ratio := time_left / max_time if max_time > 0.0 else 1.0
	danger_level = clampf(1.0 - time_ratio / DANGER_START_RATIO, 0.0, 1.0)


func _on_time_expired() -> void:
	print("HUD recebeu: tempo acabou!")
	danger_level = 0.0


func _on_progress_updated(progress_value: float, max_value: float) -> void:
	var delta_value := progress_value - last_progress
	last_progress = progress_value

	if delta_value > 0.0:
		positive_audio.play()
	else:
		negative_audio.play()

	_show_floating_text(delta_value)

	var tween = get_tree().create_tween()
	tween.parallel().tween_property(level_progress_bar, "value", progress_value, 0.2)
	level_progress_bar.max_value = max_value


func _on_progress_completed() -> void:
	positive_audio2.play()
	level_progress_bar.value = level_progress_bar.max_value
	print("HUD recebeu: progresso completo!")

func _process_danger(delta: float) -> void:
	if danger_level <= 0.0:
		danger_overlay.modulate.a = 0.0
		return

	# Acumula a fase para a velocidade poder mudar sem "pulos" no pulso
	blink_phase += delta * lerpf(BLINK_SPEED_MIN, BLINK_SPEED_MAX, danger_level)
	var pulse := (sin(blink_phase) + 1.0) * 0.5  # 0..1
	var base_alpha := danger_level * DANGER_MAX_ALPHA
	danger_overlay.modulate.a = base_alpha * lerpf(BLINK_MIN_INTENSITY, 1.0, pulse)

func _show_floating_text(value: float) -> void:
	if is_zero_approx(value):
		return

	if floating_text_tween:
		floating_text_tween.kill()

	floating_text.text = "%+d" % int(value)
	floating_text.modulate = FLOAT_COLOR_GAIN if value > 0.0 else FLOAT_COLOR_LOSS
	floating_text.position.y = floating_text_base_y
	floating_text.scale = Vector2.ONE * 0.5
	floating_text.visible = true

	floating_text_tween = create_tween().set_parallel(true)
	floating_text_tween.tween_property(floating_text, "position:y", floating_text_base_y - FLOAT_TEXT_RISE, 0.9) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	floating_text_tween.tween_property(floating_text, "scale", Vector2.ONE, 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	floating_text_tween.tween_property(floating_text, "modulate:a", 0.0, 0.4).set_delay(0.5)
	floating_text_tween.chain().tween_callback(floating_text.hide)
