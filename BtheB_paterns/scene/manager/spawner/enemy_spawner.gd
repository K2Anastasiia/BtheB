extends Node

@onready var timer: Timer = $Timer

@export var error_scene: PackedScene
@export var arena_time_manager: ArenaTimeManager
@export var warning_scene: PackedScene
@export var messenge_scene: PackedScene
@export var spawn_area: Area2D  # зона спавна

var base_spawn_time
var min_spawn_time = 0.2
var difficulty_multipleier = 0.01
var enemy_pool = EnemyPoll.new()
var max_mobs = 6
var current_mobs = 0

func _ready() -> void:
	enemy_pool.add_mob(error_scene, 30)
	base_spawn_time = timer.wait_time
	arena_time_manager.difficulty_increased.connect(on_difficulty_increased)

func start_spawn():
	print("✅ start_spawn() вызван")
	await get_tree().process_frame  # подождать кадр, чтобы всё загрузилось
	if not timer.is_stopped():
		print("⚠️ Таймер уже работает")
		return
	print("🟢 Запускаем спавн таймером")
	timer.start()

func _on_timer_timeout():
	print("⏲️ Таймер сработал")
	if current_mobs >= max_mobs:
		print("🔴 Лимит мобов достигнут: ", current_mobs)
		timer.stop()
		return

	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		print("⚠️ Игрок не найден")
		return

	var chosen_mob = enemy_pool.pick_mob()
	var enemy = chosen_mob.instantiate() as Node2D
	var back_layer = get_tree().get_first_node_in_group("back_layer")

	var spawn_position = get_spawn_position()
	if spawn_position == Vector2.INF:
		print("❌ Не удалось найти позицию для спавна.")
		return

	print("🧿 Спавним моба в позиции: ", spawn_position)
	back_layer.add_child(enemy)
	enemy.global_position = spawn_position

	current_mobs += 1
	enemy.tree_exited.connect(_on_enemy_removed)

func _on_enemy_removed():
	current_mobs = max(0, current_mobs - 1)
	print("⚰️ Моб удалён. Текущие: ", current_mobs)
	# Спавн НЕ возобновляем!


func on_difficulty_increased(difficulty_level: int):
	var new_spawn_time = max(min_spawn_time, base_spawn_time - difficulty_level * difficulty_multipleier)
	timer.wait_time = new_spawn_time

	if difficulty_level == 1:
		enemy_pool.add_mob(warning_scene, 70)
		enemy_pool.add_mob(messenge_scene, 70)

func get_spawn_position() -> Vector2:
	if spawn_area == null:
		push_error("❌ SpawnBounds не назначен!")
		return Vector2.ZERO

	if spawn_area.get_shape_owners().is_empty():
		push_error("❌ Нет форм у SpawnBounds")
		return Vector2.ZERO

	var owner_id = spawn_area.get_shape_owners()[0]
	var shape = spawn_area.shape_owner_get_shape(owner_id, 0)

	if not shape is RectangleShape2D:
		push_error("❌ Форма не RectangleShape2D")
		return Vector2.ZERO

	var extents = shape.extents
	var transform = spawn_area.global_transform

	# 💡 Ключ: учесть смещение CollisionShape2D
	var shape_node = spawn_area.get_node("CollisionShape2D") as CollisionShape2D
	var shape_offset = shape_node.position if shape_node else Vector2.ZERO

	for i in 24:
		var local_point = Vector2(
			randf_range(-extents.x, extents.x),
			randf_range(-extents.y, extents.y)
		)

		# 💥 Учитываем offset формы!
		var spawn_position = transform * (local_point + shape_offset)

		print("📍 [SPAWN DEBUG] local+offset:", local_point + shape_offset, " → global:", spawn_position)

		var point_check = PhysicsPointQueryParameters2D.new()
		point_check.position = spawn_position
		point_check.collide_with_areas = false
		point_check.collide_with_bodies = true
		point_check.collision_mask = 1 << 1

		var result = get_tree().root.world_2d.direct_space_state.intersect_point(point_check)
		if result.is_empty():
			return spawn_position

	print("❗ Не удалось найти безопасную позицию")
	return Vector2.INF
