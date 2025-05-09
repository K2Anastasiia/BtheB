extends CharacterBody2D

@onready var health_component = $HealthComponent
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var movement_component = $MovementComponent

@export var death_scene: PackedScene
@export var shadow: Sprite2D
@export var sprite: CompressedTexture2D

var flash_shader: ShaderMaterial = null

func _ready():
	# ⏳ Ждём 1 кадр, чтобы узлы успели инициализироваться
	
	await get_tree().process_frame

	# 📡 Подключаем сигнал смерти
	health_component.died.connect(on_died)

	# ⚡ Надёжно загружаем FlashComponent и flash_shader
	var flash_component := $FlashComponent
	while not flash_component or not flash_component.flash_material:
		await get_tree().process_frame
		flash_component = $FlashComponent

	flash_shader = flash_component.flash_material as ShaderMaterial

	

func _process(delta):
	move_shadow()

	var direction = movement_component.get_direction()
	movement_component.move_to_player(self)

	if direction.x != 0 or direction.y != 0:
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")

	var face_sign = sign(direction.x)
	if face_sign != 0:
		animated_sprite_2d.scale.x = face_sign


func on_died():
	var back_layer = get_tree().get_first_node_in_group("back_layer")
	var death_instance = death_scene.instantiate() as DeathComp

	if death_instance != null:
		back_layer.add_child(death_instance)

		# 🌀 Задаём текстуру для эффекта смерти (частицы)
		if death_instance.particles_2d != null:
			death_instance.particles_2d.texture = sprite

		# ⚙️ Подгоняем вертикальное смещение спрайта
		if death_instance.sprite_offset != null:
			death_instance.sprite_offset.position.y = animated_sprite_2d.offset.y

		# 📍 Устанавливаем позицию появления
		death_instance.global_position = global_position
	else:
		print("Ошибка: death_instance = null")

	# ❌ Удаляем врага
	queue_free()



func move_shadow():
	if shadow != null:
		shadow.position = Vector2(0, 0)
