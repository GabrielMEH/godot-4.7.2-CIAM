# minigame_base.gd
class_name MinigameBase
extends Node2D

signal minigame_finished(success: bool, value: float)

func _finish(success: bool, value: float) -> void:
	print("minigame: finished")
	minigame_finished.emit(success, value)
