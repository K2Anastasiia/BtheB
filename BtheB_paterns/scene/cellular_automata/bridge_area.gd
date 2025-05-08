extends Node2D

@export var generator_path: NodePath
@export var timer_path: NodePath
@export var player_node_path: NodePath
@export var interval: float = 2.0
@export var cell_size: int = 16
@export var debug_draw_enabled: bool = true

var rules := [90, 30, 60, 180]
var current_row: Array = []
var generation: int = 0
var is_ready: bool = true
var danger_timer: float = 0.2
var debug_cell := Vector2i.ZERO

@onready var bridge_generator = get_node(generator_path)
@onready var timer: Timer = get_node(timer_path)
@onready var player: CharacterBody2D = get_node(player_node_path)

func _ready():
	timer.wait_time = interval
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

	current_row = _random_row()
	for i in range(bridge_generator.width):
		var rule_index = int(generation / 3.0) % rules.size()
		var rule_table = _create_rule_table(rules[rule_index])
		bridge_generator.shift_columns_left()
		bridge_generator.draw_right_column(current_row)
		current_row = _next_generation(current_row, rule_table)
		generation += 1

func _on_timer_timeout():
	is_ready = false
	@warning_ignore("integer_division")
	var rule_table = _create_rule_table(rules[(generation / 3) % rules.size()])
	current_row = _next_generation(current_row, rule_table)
	bridge_generator.shift_columns_left()
	bridge_generator.draw_right_column(current_row)
	generation += 1
	await get_tree().process_frame
	is_ready = true

func _random_row() -> Array:
	var row := []
	for i in bridge_generator.height:
		row.append(0)
	var live_count = randi_range(1, bridge_generator.height - 1)
	var indices = range(bridge_generator.height)
	indices.shuffle()
	for i in live_count:
		row[indices[i]] = 1
	return row

func _create_rule_table(rule: int) -> Array:
	var binary := rule_to_bin(rule)
	var table := []
	for i in binary.length():
		table.append(int(binary[i]))
	return table

func rule_to_bin(n: int) -> String:
	var bin_str := ""
	for i in range(7, -1, -1):
		bin_str += str((n >> i) & 1)
	return bin_str

func _next_generation(prev: Array, table: Array) -> Array:
	var next := []
	for i in prev.size():
		var l = prev[(i - 1 + prev.size()) % prev.size()]
		var c = prev[i]
		var r = prev[(i + 1) % prev.size()]
		var pattern = (l << 2) | (c << 1) | r
		next.append(table[7 - pattern])
	return next

func _process(delta):
	if not is_inside_tree() or not player or not is_ready:
		return

	# Обновляем debug_cell
	var local_pos = player.global_position - global_position + Vector2(cell_size / 2.0, cell_size / 2.0)
	debug_cell.x = int(floor(local_pos.x / cell_size))
	debug_cell.y = int(floor(local_pos.y / cell_size))

	queue_redraw()

	# Проверка на урон
	if debug_cell.x < 0 or debug_cell.x >= bridge_generator.width or debug_cell.y < 0 or debug_cell.y >= bridge_generator.height:
		danger_timer = 0.0
		return

	var cell = bridge_generator.get_cell(debug_cell.x, debug_cell.y)
	if cell and "is_alive" in cell:
		if not cell.is_alive:
			danger_timer += delta
			if danger_timer >= 0.4:
				print("⚠ Урон: игрок простоял 0.4 сек на мёртвой клетке")
				_trigger_death()
				danger_timer = 0.0
		else:
			danger_timer = 0.0

func _trigger_death():
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
	if not debug_draw_enabled or bridge_generator == null:
		return

	var grid_size = Vector2(bridge_generator.width, bridge_generator.height) * cell_size
	var grid_rect = Rect2(Vector2.ZERO, grid_size)
	draw_rect(grid_rect, Color(0.0, 0.1, 0.0, 0.0), true)

	# Подсветка текущей клетки игрока
	if debug_cell.x >= 0 and debug_cell.x < bridge_generator.width and debug_cell.y >= 0 and debug_cell.y < bridge_generator.height:
		var cell_pos = Vector2(debug_cell) * cell_size
		draw_rect(Rect2(cell_pos, Vector2(cell_size, cell_size)), Color.GREEN, false)

	# Отрисовка всех мёртвых клеток
	for x in bridge_generator.width:
		for y in bridge_generator.height:
			var cell = bridge_generator.get_cell(x, y)
			if cell and "is_alive" in cell and not cell.is_alive:
				var pos = Vector2(x, y) * cell_size
				draw_rect(Rect2(pos, Vector2(cell_size, cell_size)), Color.BLACK, false)
