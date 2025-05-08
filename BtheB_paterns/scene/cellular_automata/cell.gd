extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
var is_alive: bool = false

func set_alive(alive: bool):
	is_alive = alive
	sprite.visible = alive
