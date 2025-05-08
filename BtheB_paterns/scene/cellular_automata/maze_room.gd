extends Node2D

@export var width: int = 25
@export var height: int = 25
@export var cell_size: int = 16
@export var player_path: NodePath
@export var WallScene1: PackedScene
@export var WallScene2: PackedScene

@onready var player = get_node(player_path)
@onready var regen_timer: Timer = $Timer

var grid: Array = []
var previous_grid: Array = []
var wall_pool: Array[Node2D] = []
var active_walls: Array[Node2D] = []

var idle_timer := 0.0
const IDLE_REGEN_TIME := 2.5

var last_cell := Vector2i(-1, -1)

func _ready():
	regen_timer.timeout.connect(_on_regen_timer_timeout)
	generate_labyrinth()

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var local_pos = player.global_position - global_position
	var cx = int(local_pos.x / cell_size)
	var cy = int(local_pos.y / cell_size)
	var current_cell = Vector2i(cx, cy)

	var in_bounds = cx >= 0 and cy >= 0 and cx < width and cy < height

	if not in_bounds:
		idle_timer = 0.0
		return

	if current_cell == last_cell:
		idle_timer += delta
		if idle_timer >= IDLE_REGEN_TIME:
			generate_labyrinth()
			idle_timer = 0.0
	else:
		idle_timer = 0.0
		last_cell = current_cell

	queue_redraw()

func generate_labyrinth():
	_clear_old_walls()
	previous_grid = grid.duplicate(true)
	grid = _create_noise_grid()

	var entrance = Vector2i(width - 1, 0)
	var exit = Vector2i(0, height - 1)

	var player_cell = Vector2i(-1, -1)
	if is_instance_valid(player):
		player_cell = Vector2i(
			int((player.global_position.x - global_position.x) / cell_size),
			int((player.global_position.y - global_position.y) / cell_size)
		)

	for i in range(20):
		grid = _apply_rules(grid, entrance, exit, player_cell)

	if entrance.x >= 0 and entrance.x < width and entrance.y >= 0 and entrance.y < height:
		grid[entrance.y][entrance.x] = 0
	if exit.x >= 0 and exit.x < width and exit.y >= 0 and exit.y < height:
		grid[exit.y][exit.x] = 0
	if player_cell.x >= 0 and player_cell.x < width and player_cell.y >= 0 and player_cell.y < height:
		grid[player_cell.y][player_cell.x] = 0

	_draw_walls()

func _create_noise_grid() -> Array:
	var new_grid: Array = []
	for y in range(height):
		var row := []
		for x in range(width):
			row.append(0 if randf() < 0.5 else 1)
		new_grid.append(row)
	return new_grid

func _apply_rules(current: Array, entrance: Vector2i, exit: Vector2i, player_cell: Vector2i) -> Array:
	var new_grid: Array = []
	for y in range(height):
		var row := []
		for x in range(width):
			if (x == entrance.x and y == entrance.y) or \
   				(x == exit.x and y == exit.y) or \
   				(x == player_cell.x and y == player_cell.y):
				row.append(0)
				continue

			var cell = current[y][x]
			var neighbors = _count_neighbors(current, x, y)
			var corners = _count_corners(current, x, y)
			var edges = _count_edges(current, x, y)

			if x % 2 == 1 and y % 2 == 1:
				row.append(0)
			elif cell == 0 and neighbors <= 2:
				row.append(1)
			elif cell == 1 and corners > edges and randf() < 0.3:
				row.append(0)
			else:
				row.append(cell)
		new_grid.append(row)
	return new_grid

func _count_neighbors(g: Array, x: int, y: int) -> int:
	var count := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = x + dx
			var ny = y + dy
			if nx >= 0 and ny >= 0 and nx < width and ny < height:
				count += g[ny][nx]
	return count

func _count_corners(g: Array, x: int, y: int) -> int:
	var coords = [[-1,-1], [1,-1], [-1,1], [1,1]]
	var count := 0
	for offset in coords:
		var nx = x + offset[0]
		var ny = y + offset[1]
		if nx >= 0 and ny >= 0 and nx < width and ny < height:
			count += g[ny][nx]
	return count

func _count_edges(g: Array, x: int, y: int) -> int:
	var coords = [[0,-1], [-1,0], [1,0], [0,1]]
	var count := 0
	for offset in coords:
		var nx = x + offset[0]
		var ny = y + offset[1]
		if nx >= 0 and ny >= 0 and nx < width and ny < height:
			count += g[ny][nx]
	return count

func _get_wall_from_pool(scene: PackedScene) -> Node2D:
	var wall: Node2D
	if wall_pool.is_empty():
		wall = scene.instantiate()
	else:
		wall = wall_pool.pop_back()

	if wall.get_parent() == null:
		add_child(wall)

	wall.show()
	return wall

func _return_wall_to_pool(wall: Node2D) -> void:
	if is_instance_valid(wall):
		wall.hide()
		if wall.get_parent() != null:
			wall.get_parent().remove_child(wall)
		wall_pool.append(wall)

func _clear_old_walls():
	for wall in active_walls:
		if is_instance_valid(wall):
			_return_wall_to_pool(wall)
	active_walls.clear()

func _draw_walls():
	for y in range(height):
		for x in range(width):
			if grid[y][x] == 1:
				var scene = WallScene1 if randf() < 0.7 else WallScene2
				var wall = _get_wall_from_pool(scene)
				wall.position = Vector2(x, y) * cell_size + Vector2(cell_size / 2.0, cell_size / 2.0)
				active_walls.append(wall)

				# Вызов Dirty Flag, если реализован
				if wall.has_method("mark_dirty"):
					wall.mark_dirty()

func _on_regen_timer_timeout():
	if is_instance_valid(player):
		generate_labyrinth()

func _draw() -> void:
	#if grid.is_empty():
		#return
#
	#var grid_size = Vector2(width, height) * cell_size
	#var grid_rect = Rect2(Vector2.ZERO, grid_size)
	#draw_rect(grid_rect, Color(0.2, 0.2, 0.2, 0.05), true)
#
	#for y in range(height):
		#for x in range(width):
			#var cell_rect = Rect2(Vector2(x, y) * cell_size, Vector2(cell_size, cell_size))
			#draw_rect(cell_rect, Color(0.2, 0.2, 0.2, 0.1), false)
#
	#if is_instance_valid(player):
		#var local_player_pos = player.global_position - global_position
		#var player_cell = Vector2i(
			#int(local_player_pos.x / cell_size),
			#int(local_player_pos.y / cell_size)
		#)
		#if player_cell.x >= 0 and player_cell.y >= 0 and player_cell.x < width and player_cell.y < height:
			#var cell_pos = Vector2(player_cell) * cell_size
			#draw_rect(Rect2(cell_pos, Vector2(cell_size, cell_size)), Color(0, 1, 0, 0), false)
		pass
