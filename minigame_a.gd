class_name MinigameA
extends MinigameBase

func _on_win_condition_met() -> void:
	_finish(true)

func _on_lose_condition_met() -> void:
	_finish(false)	
