extends Node2D

func set_alive(active: bool) -> void:
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate.a = 1.0 if active else 0.3
	else:
		push_warning("⚠ Sprite2D не найден в FireCell!")
