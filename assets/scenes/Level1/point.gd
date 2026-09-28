class_name Point
extends Area2D

@export var sprite: Sprite2D
@export var collision_shape: CollisionShape2D
@export var timer_ring: TextureProgressBar

var level: Node2D

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
	#conectando ao running do level
	is_running = false
	level = get_parent()
	level.running_changed.connect(change_running)
	
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
	print("%s foi clicado!" % name)

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
