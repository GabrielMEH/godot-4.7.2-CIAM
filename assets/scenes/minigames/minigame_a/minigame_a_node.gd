extends Node
var timer: float = 5.0

func _process(delta: float) -> void:
	if timer > 0:
		timer -= delta
	else:
		timer = 0
		get_parent()._on_win_condition_met()
