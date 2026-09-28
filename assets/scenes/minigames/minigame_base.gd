# minigame_base.gd
class_name MinigameBase
extends Node2D

signal minigame_finished(success: bool)

func _finish(success: bool) -> void:
	minigame_finished.emit(success)
