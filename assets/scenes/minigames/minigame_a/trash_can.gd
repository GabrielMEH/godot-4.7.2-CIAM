extends Area2D

signal trash_delivered

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("trash"):
		trash_delivered.emit()
