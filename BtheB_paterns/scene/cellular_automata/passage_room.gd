extends Node2D

@export var player: Node2D
@export var cell_size: int = 16
@export var tick_interval: float = 1.5
@export var damage_delay: float = 0.2  # Задержка перед уроном

@onready var feeder := $Rule30Feeder
@onready var grid := $GameOfLifeGrid

var timer := 0.0
var danger_timer := 0.0
var debug_in_bounds := false
var debug_cell := Vector2i(-1, -1)

func _process(delta: float) -> void:
	timer += delta
	if timer >= tick_interval:
		timer = 0.0
		_step()

	_check_player_collision(delta)
	queue_redraw()  # Чтобы перерисовать зону в редакторе

func _step():
	var rule_row = feeder.get_next_row()
	grid.feed_from_right(rule_row)
	grid.step()

func _check_player_collision(delta: float) -> void:
	if player == null or grid == null:
		return

	var local_pos: Vector2 = grid.to_local(player.global_position)
	var cell_x: int = int(floor(local_pos.x / cell_size))
	var cell_y: int = int(floor(local_pos.y / cell_size))
	debug_cell = Vector2i(cell_x, cell_y)

	var in_bounds: bool = (
		cell_x >= 0 and cell_x < grid.get_cols() and
		cell_y >= 0 and cell_y < grid.get_rows() and
		local_pos.x >= 0 and local_pos.x < grid.get_cols() * cell_size and
		local_pos.y >= 0 and local_pos.y < grid.get_rows() * cell_size
	)
	debug_in_bounds = in_bounds

	if not in_bounds:
		danger_timer = 0.0
		return

	if grid.is_alive_at(cell_x, cell_y):
		danger_timer += delta
		if danger_timer >= damage_delay:
			print("🔥 УРОН: игрок на живой клетке в ячейке", cell_x, cell_y)
			_emit_player_hit()
			danger_timer = 0.0
	else:
		danger_timer = 0.0

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

# 🎨 Визуализация зоны грида и выделенной ячейки
func _draw() -> void:
	if grid == null:
		return

	var cols = grid.get_cols()
	var rows = grid.get_rows()
	var grid_size = Vector2(cols, rows) * cell_size

	var grid_rect = Rect2(grid.global_position - global_position, grid_size)
	draw_rect(grid_rect, Color(0.2, 0.2, 0.2, 0), true)  # полупрозрачный зелёный прямоугольник

	# Отладка: выделим текущую ячейку игрока
	if debug_in_bounds:
		var cell_pos = grid_rect.position + Vector2(debug_cell.x, debug_cell.y) * cell_size
		draw_rect(Rect2(cell_pos, Vector2(cell_size, cell_size)), Color(0, 1, 0, 0.3), false)
