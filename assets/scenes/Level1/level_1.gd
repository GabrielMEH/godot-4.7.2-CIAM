extends Node2D

signal time_updated(time_left: float, max_time: float)
signal time_expired
signal progress_updated(progress: float, max_time: float)
signal progress_finished
signal running_changed(value: bool)

var is_running: bool = true
@export var level_data: LevelData
var point_cooldown_timer: float
var time_limit_timer: float
var progress_limit: float
var progress_limit_curr: float

#pontos do nível, pontos filhos do node Level1
var points: Array[Node] = []

#configura o nível
func _ready() -> void:
	randomize()
	time_limit_timer = level_data.time_limit
	progress_limit_curr = 0
	is_running = true
	time_updated.emit(time_limit_timer, level_data.time_limit)
	point_cooldown_timer = level_data.point_cooldown
	points = get_tree().get_nodes_in_group("points")

	points = get_tree().get_nodes_in_group("points")

func _process(delta: float) -> void:
	process_time(delta)
	process_point(delta)

#reduz timer do nivel
func process_time(delta: float) -> void:
	if is_running and time_limit_timer > 0:
		time_limit_timer -= delta
		time_limit_timer = max(time_limit_timer, 0)
		time_updated.emit(time_limit_timer, level_data.time_limit)
		if time_limit_timer == 0:
			is_running = false
			time_up()

#processa a ativação de pontos
func process_point(delta: float) -> void:
	if is_running and point_cooldown_timer > 0:
		point_cooldown_timer -= delta
		point_cooldown_timer = max(point_cooldown_timer, 0)
		if point_cooldown_timer == 0:
			var free_point = get_free_point()
			if free_point:
				free_point.activate(level_data.point_active_duration)
				point_cooldown_timer = level_data.point_cooldown
				print(free_point.name + " ativado")

#pega pontos livres
func get_free_point() -> Node:
	var free_points := points.filter(func(p): return p.is_free)
	if free_points.is_empty():
		return null
	return free_points.pick_random()

#adiciona ou remove tempo
func time_change(value: float) -> void:
	time_limit_timer += value
	time_updated.emit(time_limit_timer, level_data.time_limit)

#acabou o tempo
func time_up() -> void:
	is_running = false
	print("Time's up!")
	time_expired.emit()

func change_running(value: bool):
	is_running = value
	running_changed.emit(value)
	
func progress(value: float) -> void:
	if progress_limit_curr + value >= level_data.progress_required:
		progress_limit_curr = level_data.progress_required
		progress_finished.emit()
	else:
		progress_limit_curr += value
		progress_updated.emit(progress_limit_curr, level_data.progress_required)
