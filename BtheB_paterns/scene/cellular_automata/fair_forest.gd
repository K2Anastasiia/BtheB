extends Node2D

@export var player: Node2D
@export var fire_cell_scene_1: PackedScene
@export var fire_cell_scene_2: PackedScene
@export var burned_cell_scene_1: PackedScene
@export var burned_cell_scene_2: PackedScene

@export var grid_size := 20
@export var cell_size := 16
@export var damage_delay := 0.2

@onready var fire_layer := $FireLayer
@onready var timer := $Timer

enum CellState { GRASS, FIRE, BURNED, DIRT, TREE }

var grid: Array = []
var fire_pool: Array = []
var burned_pool: Array = []

var debug_cell := Vector2i(-1, -1)
var debug_in_bounds := false
var danger_timer := 0.0
var simulation_running := false

func _ready():
	randomize()
	_init_grid()
	_init_fire_pool()
	timer.timeout.connect(_on_step)
	timer.wait_time = 0.3

func _process(delta: float) -> void:
	_check_player_collision(delta)
	if simulation_running:
		queue_redraw()

func _init_grid():
	grid.clear()
	for y in range(grid_size + 2):
		var row = []
		for x in range(grid_size + 2):
			var cell = CellState.TREE if randf() < 0.7 else CellState.GRASS
			row.append(cell)
		grid.append(row)
	grid[10][10] = CellState.FIRE

func _init_fire_pool():
	for child in fire_layer.get_children():
		child.queue_free()
	fire_pool.clear()
	burned_pool.clear()

	var max_cells = grid_size * grid_size
	for i in range(max_cells):
		var fire_scene = fire_cell_scene_1 if randi() % 2 == 0 else fire_cell_scene_2
		var burned_scene = burned_cell_scene_1 if randi() % 2 == 0 else burned_cell_scene_2

		var fire_cell = fire_scene.instantiate()
		var burned_cell = burned_scene.instantiate()

		fire_cell.visible = false
		burned_cell.visible = false
		fire_cell.position = Vector2(-1000, -1000)
		burned_cell.position = Vector2(-1000, -1000)

		if fire_cell.has_method("set_alive"):
			fire_cell.set_alive(false)
		else:
			push_warning("⚠ fire_cell не содержит set_alive(): " + str(fire_cell))

		fire_layer.add_child(fire_cell)
		fire_layer.add_child(burned_cell)

		fire_pool.append(fire_cell)
		burned_pool.append(burned_cell)

func _on_step():
	var new_grid = []
	for y in range(grid_size + 2):
		var row = []
		for x in range(grid_size + 2):
			var state = grid[y][x]
			var next_state = state

			if state == CellState.TREE and _has_burning_neighbor(x, y):
				next_state = CellState.FIRE
			elif state == CellState.FIRE:
				next_state = CellState.BURNED
			elif state == CellState.BURNED:
				next_state = CellState.DIRT

			row.append(next_state)
		new_grid.append(row)

	grid = new_grid
	_draw_fire()

func _has_burning_neighbor(x: int, y: int) -> bool:
	var offsets = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for offset in offsets:
		var nx = x + offset.x
		var ny = y + offset.y
		if nx >= 0 and nx < grid_size + 2 and ny >= 0 and ny < grid_size + 2:
			if grid[ny][nx] == CellState.FIRE:
				return true
	return false

func _draw_fire():
	var index_fire := 0
	var index_burned := 0

	for y in range(grid_size):
		for x in range(grid_size):
			var gx = x + 1
			var gy = y + 1
			var state = grid[gy][gx]
			var pos = Vector2(x * cell_size, y * cell_size) + Vector2(cell_size, cell_size) / 2

			if state == CellState.FIRE and index_fire < fire_pool.size():
				var fire_cell = fire_pool[index_fire]
				fire_cell.position = pos
				fire_cell.visible = true
				fire_cell.set_alive(true)
				index_fire += 1
			elif state == CellState.BURNED and index_burned < burned_pool.size():
				var burned_cell = burned_pool[index_burned]
				burned_cell.position = pos
				burned_cell.visible = true
				index_burned += 1

	for i in range(index_fire, fire_pool.size()):
		fire_pool[i].set_alive(false)
		fire_pool[i].visible = false
		fire_pool[i].position = Vector2(-1000, -1000)

	for i in range(index_burned, burned_pool.size()):
		burned_pool[i].visible = false
		burned_pool[i].position = Vector2(-1000, -1000)

func _check_player_collision(delta: float):
	if player == null:
		danger_timer = 0.0
		_stop_simulation()
		return

	var pos = player.global_position - global_position
	var cx = int(pos.x / cell_size)
	var cy = int(pos.y / cell_size)

	debug_cell = Vector2i(cx, cy)
	debug_in_bounds = cx >= 0 and cx < grid_size and cy >= 0 and cy < grid_size

	if debug_in_bounds:
		if not simulation_running:
			_init_grid()
		_start_simulation()
		var state = grid[cy + 1][cx + 1]
		if state == CellState.FIRE or state == CellState.BURNED:
			danger_timer += delta
			if danger_timer >= damage_delay:
				_emit_player_hit()
				danger_timer = 0.0
		else:
			danger_timer = 0.0
	else:
		danger_timer = 0.0
		_stop_simulation()

func _start_simulation():
	if not simulation_running:
		simulation_running = true
		timer.start()
		print("▶️ Симуляция ЗАПУЩЕНА")

func _stop_simulation():
	if simulation_running:
		simulation_running = false
		timer.stop()
		_clear_fire_layer()
		print("⏹️ Симуляция ОСТАНОВЛЕНА")

func _clear_fire_layer():
	for fire_cell in fire_pool:
		fire_cell.set_alive(false)
		fire_cell.visible = false
		fire_cell.position = Vector2(-1000, -1000)
	for burned_cell in burned_pool:
		burned_cell.visible = false
		burned_cell.position = Vector2(-1000, -1000)

func _emit_player_hit():
	print("💥 Столкновение! Игрок получает урон.")
	if player.has_node("HealthComponent"):
		var hp = player.get_node("HealthComponent")
		if hp.has_method("get_max_health"):
			var max_hp = hp.get_max_health()
			var damage = max(1, round(max_hp * 0.1))
			print("→ Наносим урон:", damage)
			hp.take_damage(damage)
		else:
			hp.take_damage(1)

	if player.has_method("trigger_glitch_effect"):
		player.trigger_glitch_effect()

func _draw():
	var total_size = grid_size * cell_size

	# Сетка
	for y in range(grid_size + 1):
		var y_pos = y * cell_size
		draw_line(Vector2(0, y_pos), Vector2(total_size, y_pos), Color(1, 1, 1, 0))
	for x in range(grid_size + 1):
		var x_pos = x * cell_size
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, total_size), Color(1, 1, 1, 0))

	if debug_in_bounds:
		var cell_pos = Vector2(debug_cell) * cell_size
		draw_rect(Rect2(cell_pos, Vector2(cell_size, cell_size)), Color(0, 1, 0, 0.0), false)
