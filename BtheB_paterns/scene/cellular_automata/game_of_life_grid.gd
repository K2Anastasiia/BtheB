extends Node2D

@export var generator_path: NodePath
@export var timer_path: NodePath 
@export var interval: float = 2.0
@export var cell_gl1: PackedScene
@export var cell_gl2: PackedScene

const ROWS := 36
const COLS := 18
const CELL_SIZE := 16

var sprite_pool: Array = []
var sprite_grid: Array = []
var grid: Array = []

@onready var cells: Node2D = $Cells
@onready var timer: Timer = get_node_or_null(timer_path)
@onready var bridge_generator = get_node_or_null(generator_path)

func _ready():
	if timer == null:
		push_error("⛔ Timer не найден! Назначьте timer_path.")
		return
	if bridge_generator == null:
		push_error("⛔ Генератор не найден! Назначьте generator_path.")
		return

	grid.resize(ROWS)
	sprite_grid.resize(ROWS)
	for y in range(ROWS):
		grid[y] = []
		sprite_grid[y] = []

	timer.wait_time = interval
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout():
	var next_row = bridge_generator.get_next_row()
	feed_from_right(next_row)
	step()

func feed_from_right(rule_row: Array[int]):
	# Сдвигаем каждую строку ВЛЕВО, вставляя справа по элементу из rule_row
	for y in range(ROWS):
		if grid[y].size() >= COLS:
			grid[y].pop_front()
			var old_sprite = sprite_grid[y].pop_front()
			if old_sprite:
				old_sprite.visible = false
				if old_sprite.get_parent() != null:
					old_sprite.get_parent().remove_child(old_sprite)
				sprite_pool.append(old_sprite)

		var alive: int = rule_row[y % rule_row.size()]  # Подставляем значение из Rule 30
		grid[y].append(alive)
		sprite_grid[y].append(null)


func step():
	var next := []

	for y in range(ROWS):
		var new_row := []

		for x in range(grid[y].size()):
			var alive: int = grid[y][x]
			var sum := 0

			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if dx == 0 and dy == 0:
						continue
					var ny = (y + dy + ROWS) % ROWS
					var nx = (x + dx + COLS) % COLS
					if nx < grid[ny].size():
						sum += grid[ny][nx]

			var result := 1 if (sum == 3 or (alive == 1 and sum == 2)) else 0
			new_row.append(result)

		next.append(new_row)

	_update_sprites(next)
	grid = next

func _update_sprites(new_grid: Array) -> void:
	for y in range(ROWS):
		if y >= sprite_grid.size():
			continue
		if sprite_grid[y] == null:
			sprite_grid[y] = []

		for x in range(COLS):
			if y >= new_grid.size() or x >= new_grid[y].size():
				continue

			var alive: int = new_grid[y][x]

			if x >= sprite_grid[y].size():
				sprite_grid[y].resize(COLS)
				for i in range(sprite_grid[y].size()):
					if sprite_grid[y][i] == null:
						sprite_grid[y][i] = null

			var sprite = sprite_grid[y][x]

			if alive == 1:
				if sprite == null:
					var prefab = cell_gl1 if randf() < 0.5 else cell_gl2
					if prefab == null or not prefab is PackedScene:
						push_warning("⚠️ prefab не назначен или не является PackedScene")
						continue

					var s = _get_sprite_from_pool(prefab)
					if s == null:
						push_warning("❗ Sprite из пула не получен!")
						continue

					s.visible = true
					s.position = Vector2(x * CELL_SIZE + CELL_SIZE / 2.0, y * CELL_SIZE + CELL_SIZE / 2.0)
					cells.add_child(s)
					sprite_grid[y][x] = s
			elif sprite:
				sprite.visible = false
				if sprite.get_parent() != null:
					sprite.get_parent().remove_child(sprite)

				sprite_pool.append(sprite)
				sprite_grid[y][x] = null


func _get_sprite_from_pool(prefab: PackedScene) -> Sprite2D:
	var sprite = sprite_pool.pop_back() if sprite_pool.size() > 0 else prefab.instantiate()
	if sprite is Sprite2D:
		return sprite
	return null

# --- Методы для внешнего доступа ---
func get_cols() -> int:
	return COLS

func get_rows() -> int:
	return ROWS

func is_alive_at(x: int, y: int) -> bool:
	if y < 0 or y >= grid.size():
		return false
	if x < 0 or x >= grid[y].size():
		return false
	return grid[y][x] == 1
