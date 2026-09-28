class_name MinigameA
extends MinigameBase
var timer: float = 5.0

func _on_win_condition_met() -> void:
	_finish(true)

func _on_lose_condition_met() -> void:
	_finish(false)	
