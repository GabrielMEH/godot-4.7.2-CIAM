extends CanvasLayer

@onready var time_limit_bar: ProgressBar = $time_limit_bar
@onready var level_progress_bar: ProgressBar = $level_progress_bar

func _ready() -> void:
	var level = get_parent()  #Level1 nesse caso
	level.time_updated.connect(_on_time_updated)
	level.time_expired.connect(_on_time_expired)

func _on_time_updated(time_left: float, max_time: float) -> void:
	time_limit_bar.max_value = max_time
	time_limit_bar.value = time_left

func _on_time_expired() -> void:
	print("HUD recebeu: tempo acabou!")
