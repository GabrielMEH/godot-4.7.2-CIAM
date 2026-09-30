extends CanvasLayer

@onready var time_limit_bar: TextureProgressBar = $time_limit_bar
@onready var level_progress_bar: TextureProgressBar = $level_progress_bar
@onready var counter_label: Label = $time_limit_bar/CounterLabel
func _ready() -> void:
	var level = get_parent()  #Level1 nesse caso
	level.time_updated.connect(_on_time_updated)
	level.time_expired.connect(_on_time_expired)
	level.progress_updated.connect(_on_progress_updated)
	level.progress_finished.connect(_on_progress_completed)

func _on_time_updated(time_left: float, max_time: float) -> void:
	time_limit_bar.max_value = max_time
	time_limit_bar.value = time_left
	var counter_text: String = str(int(time_left))
	counter_label.text = counter_text
	

func _on_time_expired() -> void:
	print("HUD recebeu: tempo acabou!")
	
func _on_progress_updated(progress_value: float, max_value: float) -> void:
	level_progress_bar.max_value = max_value
	level_progress_bar.value += progress_value
	
func _on_progress_completed() -> void:
	print("HUD recebeu: progresso completo!")
