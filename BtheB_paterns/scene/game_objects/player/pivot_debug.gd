extends Node2D

func _ready():
	call_deferred("_draw")  # ⬅️ форсируем отрисовку

func _draw():
	var size := 2
	draw_line(Vector2(-size, 0), Vector2(size, 0), Color.RED, 1)
	draw_line(Vector2(0, -size), Vector2(0, size), Color.RED, 1)
