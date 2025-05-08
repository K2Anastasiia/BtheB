extends Area2D

@onready var enemy_spawner: Node = get_tree().get_first_node_in_group("enemy_spawner")
@onready var room_darkness: ColorRect = $RoomDarkness

func _ready():
	print("📡 RoomTrigger готов. enemy_spawner: ", enemy_spawner)

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("🚪 Игрок вошёл в RoomTrigger")

		if room_darkness and room_darkness.material:
			var tween = create_tween()
			tween.tween_property(room_darkness.material, "shader_parameter/progress", 1.0, 2.5)
			tween.tween_callback(Callable(self, "queue_free"))  # <-- удаляем ТОЛЬКО ПОСЛЕ анимации

		if enemy_spawner and enemy_spawner.has_method("start_spawn"):
			print("📦 Спавнер найден, вызываем start_spawn()")
			enemy_spawner.start_spawn()
		else:
			push_error("❌ Спавнер не найден или метод отсутствует")
