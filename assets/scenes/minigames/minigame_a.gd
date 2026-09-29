class_name TrashMinigame
extends Node2D

signal minigame_finished(success: bool)

@export var time_limit: float = 10.0

@onready var timer: Timer = $TimeLimit
@onready var trash_can: Area2D = $TrashCan
@onready var timer_label: Label = $TimerLabel

var time_left: float = 0.0
var finished: bool = false

func _ready() -> void:
	position = get_viewport_rect().size / 2
	time_left = time_limit
	timer.wait_time = time_limit
	timer.one_shot = true
	timer.timeout.connect(_on_time_up)
	timer.start()

	trash_can.trash_delivered.connect(_on_trash_delivered)

func _process(delta: float) -> void:
	if finished:
		return
	time_left -= delta
	time_left = max(time_left, 0.0)
	timer_label.text = "%.1f" % time_left

func _on_trash_delivered() -> void:
	if finished:
		return
	finished = true
	minigame_finished.emit(true, 15)

func _on_time_up() -> void:
	if finished:
		return
	finished = true
	minigame_finished.emit(false, 10)
