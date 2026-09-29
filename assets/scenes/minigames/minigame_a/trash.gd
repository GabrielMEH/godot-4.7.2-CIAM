extends RigidBody2D

var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	input_event.connect(_on_input_event)

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_offset = global_position - get_global_mouse_position()
			freeze = true  # pausa a física enquanto arrasta
		else:
			dragging = false
			freeze = false  # devolve o controle pra física ao soltar

func _process(_delta: float) -> void:
	if dragging:
		global_position = get_global_mouse_position() + drag_offset

func _unhandled_input(event: InputEvent) -> void:
	# solta o lixo mesmo se o mouse sair da collision shape antes do release
	if dragging and event is InputEventMouseButton and not event.pressed:
		dragging = false
		freeze = false
