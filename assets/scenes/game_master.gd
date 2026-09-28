extends Node

signal progress_changed(current: float, required: float)
signal time_updated(remaining: float)
signal level_completed
signal level_failed

var current_level: LevelData
var time_remaining: float = 0.0
var progress_current: float = 0.0

var _is_running: bool = false

func _process(delta: float) -> void:
	if not _is_running:
		return
	time_remaining -= delta
	time_updated.emit(time_remaining)
	if time_remaining <= 0.0:
		_is_running = false
		level_failed.emit()

func start_level(level_data: LevelData) -> void:
	current_level = level_data
	time_remaining = level_data.time_limit
	progress_current = 0.0
	_is_running = true

func add_progress(amount: float) -> void:
	if not _is_running:
		return
	progress_current = clamp(progress_current + amount, 0.0, current_level.progress_required)
	progress_changed.emit(progress_current, current_level.progress_required)
	if progress_current >= current_level.progress_required:
		_is_running = false
		level_completed.emit()

func get_progress_ratio() -> float:
	return progress_current / current_level.progress_required if current_level.progress_required > 0 else 0.0
