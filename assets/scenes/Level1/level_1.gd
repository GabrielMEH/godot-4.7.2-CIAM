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
var progress_negative: int
var time_left: int
@onready var ember_particle: CPUParticles2D = $Hud/EmberParticle
var reds: int
var finished: bool = false  # true quando o nível acabou (vitória ou derrota)


#pontos do nível, pontos filhos do node Level1
var points: Array[Node] = []

const GAME_OVER_SCENE := preload("res://assets/scenes/gameover/GameOver.tscn")
# ajuste o caminho para onde você salvar a cena
const LEVEL_COMPLETE_SCENE := preload("res://assets/scenes/level_complete/level_complete.tscn")

# pontuação final = BASE_SCORE + (segundos restantes * TIME_BONUS_PER_SECOND) - (erros * NEGATIVE_PENALTY)
const BASE_SCORE := 1000
const TIME_BONUS_PER_SECOND := 10
const NEGATIVE_PENALTY := 100

#configura o nível
func _ready() -> void:
	randomize()
	time_limit_timer = level_data.time_limit
	progress_limit_curr = 0
	is_running = true
	time_updated.emit(time_limit_timer, level_data.time_limit)
	progress_updated.emit(0, level_data.progress_required)
	point_cooldown_timer = level_data.point_cooldown
	points = get_tree().get_nodes_in_group("points")
	
	reds = 0
	process_ember()

func _process(delta: float) -> void:
	if finished:
		return
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
			point_cooldown_timer = level_data.point_cooldown
			var free_point = get_free_point()
			if free_point:
				free_point.activate(level_data.point_active_duration)
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
	finished = true
	is_running = false
	print("Time's up!")
	time_expired.emit()
	var game_over := GAME_OVER_SCENE.instantiate()
	add_child(game_over)

func change_running(value: bool):
	is_running = value
	running_changed.emit(value)
	
func add_progress(value: float) -> void:
	if finished:
		return
	if value < 0:
		progress_negative = progress_negative + 1
	if progress_limit_curr + value >= level_data.progress_required:
		progress_limit_curr = level_data.progress_required
		progress_finished.emit()
		level_complete()
	else:
		progress_limit_curr += value
		if progress_limit_curr < 0:
			progress_limit = 0
		progress_updated.emit(progress_limit_curr, level_data.progress_required)

#nível completo: calcula a pontuação e mostra a tela de fim de nível
func level_complete() -> void:
	finished = true
	is_running = false

	var time_bonus := int(time_limit_timer) * TIME_BONUS_PER_SECOND
	var penalty := progress_negative * NEGATIVE_PENALTY
	var final_score := maxi(BASE_SCORE + time_bonus - penalty, 0)

	var screen := LEVEL_COMPLETE_SCENE.instantiate() as LevelCompleteScreen
	add_child(screen)
	screen.setup(time_bonus, penalty, final_score)
	get_tree().paused = true

func add_red() -> void:
	reds = reds + 1
	process_ember()
	
func remove_red() -> void:
	reds = reds - 1
	process_ember()

func process_ember() -> void:
	ember_particle.emitting = reds > 0
