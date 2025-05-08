extends Node2D

var is_alive: bool = false
@onready var sprite: Sprite2D = $Sprite2D

func set_alive(value: bool) -> void:
	if is_alive == value:
		return  # 🔁 Ничего не меняем — состояние не изменилось
	is_alive = value
	sprite.visible = value
