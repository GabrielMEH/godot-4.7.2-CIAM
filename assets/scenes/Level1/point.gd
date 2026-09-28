class_name Point
extends Area2D

@export var sprite: Sprite2D
@export var collision_shape: CollisionShape2D
@export var timer_ring: TextureProgressBar
@export var minigame_scenes: Array[PackedScene] = []

var level: Node2D
var minigame_layer: CanvasLayer
var current_minigame: Node = null

signal green_point()
var green_sent: bool = false
signal yellow_point()
var yellow_sent: bool = false
signal red_point()
var red_sent: bool = false

var is_running: bool = false
var is_free: bool = true
var active_timer: float = 0.0
var active_duration: float = 0.0

func _ready() -> void:
	collision_shape.disabled = true
	sprite.visible = false
	timer_ring.visible = false
	is_running = false
	level = get_parent()
	level.running_changed.connect(change_running)
	minigame_layer = level.get_node("MinigameLayer")

	input_event.connect(_on_input_event)

func _process(delta: float) -> void:
	if is_running and not is_free and active_timer > 0.0:
		active_timer -= delta
		active_timer = max(active_timer, 0.0)
		timer_ring.value = active_timer
		_update_color()

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if is_free:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_clicked()

func _on_clicked() -> void:
	level.change_running(false)
	_spawn_minigame()
	print("%s foi clicado!" % name)

func _spawn_minigame() -> void:
	if minigame_scenes.is_empty():
		push_warning("Nenhum minigame configurado em %s" % name)
		return

	var scene: PackedScene = minigame_scenes.pick_random()
	current_minigame = scene.instantiate()
	minigame_layer.add_child(current_minigame)
	current_minigame.minigame_finished.connect(_on_minigame_finished)

func _on_minigame_finished(success: bool) -> void:
	current_minigame.queue_free()
	current_minigame = null

	if success:
		print("%s: minigame concluído!" % name)
	else:
		print("%s: minigame fracassado!" % name)

	level.change_running(true)
	_deactivate()

func _deactivate() -> void:
	is_free = true
	green_sent = false
	yellow_sent = false
	red_sent = false
	sprite.visible = false
	timer_ring.visible = false
	collision_shape.disabled = true

func activate(duration: float) -> void:
	is_free = false
	is_running = true
	active_duration = duration
	active_timer = duration
	collision_shape.disabled = false
	sprite.visible = true
	timer_ring.visible = true
	timer_ring.max_value = duration
	timer_ring.value = duration
	_update_color()

func _update_color() -> void:
	var third: float = active_duration / 3.0
	if active_timer > third * 2.0:
		if green_sent == false:
			green_point.emit()
			green_sent = true
		sprite.modulate = Color.GREEN
		timer_ring.tint_progress = Color.GREEN
	elif active_timer > third:
		if yellow_sent == false:
			yellow_point.emit()
			yellow_sent = true
		sprite.modulate = Color.YELLOW
		timer_ring.tint_progress = Color.YELLOW
	else:
		if red_sent == false:
			red_point.emit()
			red_sent = true
		sprite.modulate = Color.RED
		timer_ring.tint_progress = Color.RED

func change_running(value: bool):
	is_running = value
