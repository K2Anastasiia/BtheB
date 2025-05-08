extends Node2D

@export var cell_scene: PackedScene
@export var bridge_root: Node2D
@export var width: int = 15
@export var height: int = 5
@export var cell_size: int = 16

var cell_columns: Array = []

func _ready():
	for x in width:
		var column := []
		for y in height:
			var cell = cell_scene.instantiate()

			# ✅ Центрируем по ячейке
			cell.position = Vector2(
				x * cell_size + float(cell_size) / 2,
				y * cell_size + float(cell_size) / 2
			)

			# ✅ Центрируем сам спрайт (если есть)
			if cell.has_node("Sprite2D"):
				cell.get_node("Sprite2D").centered = true

			bridge_root.add_child(cell)
			column.append(cell)
		cell_columns.append(column)

func shift_columns_left():
	for x in range(width - 1):
		for y in height:
			var next_alive = cell_columns[x + 1][y].sprite.visible
			cell_columns[x][y].set_alive(next_alive)

func draw_right_column(generation: Array):
	var last_col = width - 1
	for y in height:
		cell_columns[last_col][y].set_alive(generation[y] == 1)

func get_cell(x: int, y: int) -> Node2D:
	if x >= 0 and x < width and y >= 0 and y < height:
		return cell_columns[x][y]
	return null
