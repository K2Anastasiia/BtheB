extends Node2D

@export var cell_size: int = 16
var dirty := true  # флаг перерисовки

func _ready():
	queue_redraw()

func _draw():
	if dirty:
		dirty = false

func mark_dirty():
	dirty = true
	queue_redraw()
