class_name Point
extends Area2D

enum State { GREEN, YELLOW, RED }

@export var inner_circle: Sprite2D
@export var icon: Sprite2D
@export var collision_shape: CollisionShape2D
@export var timer_ring: TextureProgressBar
@export var minigames_yellow: Array[PackedScene] = []
@export var minigames_red: Array[PackedScene] = []

var level: Node2D
var minigame_layer: CanvasLayer
var current_minigame: Node = null
var icon_tween: Tween
var icon_base_scale_x: float


signal yellow_point()
signal red_point()

var is_running: bool = false
var is_free: bool = true
var state: State = State.GREEN

var active_timer: float = 0.0
var active_duration: float = 0.0

func _ready() -> void:
	is_running = false
	level = get_parent()
	level.running_changed.connect(change_running)
	minigame_layer = level.get_node("MinigameLayer")
	icon_base_scale_x = icon.scale.x

	input_event.connect(_on_input_event)

	_set_green()

func _process(delta: float) -> void:
	if not is_running or is_free or state == State.GREEN:
		return

	active_timer -= delta
	active_timer = max(active_timer, 0.0)
	timer_ring.value = active_timer

	if state == State.YELLOW and active_timer <= active_duration / 2.0:
		_start_red()

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if is_free or not is_running:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_clicked()

func _on_clicked() -> void:
	match state:
		State.GREEN:
			pass  # não faz nada
		State.YELLOW:
			_spawn_minigame(minigames_yellow)
		State.RED:
			_spawn_minigame(minigames_red)

func _spawn_minigame(scenes: Array[PackedScene]) -> void:
	if scenes.is_empty():
		push_warning("Nenhum minigame configurado para este estado em %s" % name)
		return

	level.change_running(false)

	var scene: PackedScene = scenes.pick_random()
	current_minigame = scene.instantiate()
	minigame_layer.add_child(current_minigame)
	current_minigame.minigame_finished.connect(_on_minigame_finished)
	print("%s foi clicado!" % name)

func _on_minigame_finished(success: bool, value: float) -> void:
	current_minigame.queue_free()
	current_minigame = null

	if success:
		print("%s: minigame concluído!" % name)
		level.add_progress(value)
	else:
		print("%s: minigame fracassado!" % name)
		level.add_progress(-value)

	level.change_running(true)
	is_free = true
	_set_green()

func _set_green() -> void:
	is_free = true
	state = State.GREEN
	inner_circle.visible = true
	inner_circle.modulate = Color.GREEN
	timer_ring.tint_progress = Color.GREEN
	timer_ring.max_value = 1.0
	timer_ring.value = 1.0
	collision_shape.set_deferred("disabled", true)
	change_icon(2,0)
	

func activate(duration: float) -> void:
	is_free = false
	is_running = true
	active_duration = duration
	active_timer = duration
	collision_shape.disabled = false
	timer_ring.max_value = duration
	timer_ring.value = duration
	_start_yellow()

func _start_yellow() -> void:
	state = State.YELLOW
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.parallel().tween_property(inner_circle, "modulate", Color.YELLOW, 1.0)
	tween.parallel().tween_property(timer_ring, "tint_progress", Color.YELLOW, 1.0)
	yellow_point.emit()
	change_icon(1,0)

func _start_red() -> void:
	state = State.RED
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.parallel().tween_property(inner_circle, "modulate", Color.ORANGE_RED, 1.0)
	tween.parallel().tween_property(timer_ring, "tint_progress", Color.ORANGE_RED, 1.0)
	red_point.emit()
	change_icon(0,0)

func change_running(value: bool):
	is_running = value

func change_icon(column: int, row: int) -> void:
	if icon_tween:
			icon_tween.kill()
	icon_tween = create_tween()
	icon_tween.tween_property(icon, "scale:x", 0.0, 0.2)
	icon_tween.tween_callback(show_icon_at.bind(column, row))
	icon_tween.tween_property(icon, "scale:x", icon_base_scale_x, 0.2)
	
func show_icon_at(column: int, row: int) -> void:
	icon.frame_coords = Vector2i(column, row)
