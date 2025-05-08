extends CharacterBody2D

@onready var health_component = $HealthComponent
@onready var grace_period = $GracePeriod
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var ability_manager: Node = $AbilityManager
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@export var shadow: Sprite2D
@export var code_background_path: NodePath


var code_background: TextureRect = null
var code_bg_shader: ShaderMaterial = null
var flash_shader: ShaderMaterial = null
var max_speed = 125
var acceleration = .15
var enemies_colliding = 0

var post_effect_rect: TextureRect = null

func _ready() -> void:
	await get_tree().process_frame  # подождать один кадр, чтобы CRTWrapper успел инициализироваться

	post_effect_rect = Global.post_effect_rect
	if post_effect_rect:
		post_effect_rect.visible = false
	else:
		push_warning("⚠ PostEffectRect не найден!")

	# Подключение сигналов
	health_component.health_changed.connect(on_health_changed)
	health_component.died.connect(on_died)
	health_update()
	
	code_background = get_node(code_background_path) as TextureRect
	if code_background:
		code_bg_shader = code_background.material as ShaderMaterial
	
	# ⚡ Безопасно инициализируем flash_shader
	var flash_component := $FlashComponent
	while not flash_component or not flash_component.flash_material:
		await get_tree().process_frame
		flash_component = $FlashComponent
	flash_shader = flash_component.flash_material as ShaderMaterial


func _process(delta):
	#check_low_health_shader()
	move_shadow()
	var direction = movement_vector().normalized()
	var target_velocity = max_speed * direction
	
	velocity = velocity.lerp(target_velocity, acceleration)
	move_and_slide()
	
	if direction.x != 0 || direction.y != 0:
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")
		
	var face_sing = sign(direction.x)
	if face_sing != 0:
		animated_sprite_2d.scale.x = face_sing
	
func movement_vector():
	var movement_x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var movement_y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	return Vector2(movement_x, movement_y)
	
	
func check_if_damaged():
	if enemies_colliding == 0 || !grace_period.is_stopped():
		return

	health_component.take_damage(1)
	animated_sprite_2d.play("hit")
	grace_period.start()

	trigger_glitch_effect()  # ← Глитч после урона

	
	
func health_update():
	progress_bar.value = health_component.get_helth_value()
	
	
	
func _on_player_hurt_box_area_entered(area):
	enemies_colliding += 1
	check_if_damaged()


func _on_player_hurt_box_area_exited(area):
	enemies_colliding -= 1
	
func on_died():
	print("☠ Игрок умер, queue_free()")
	queue_free()
	clear_glitch_effect()
	
func on_health_changed():
	health_update()

	
func _on_grace_period_timeout() -> void:
	check_if_damaged()
	


func move_shadow():
	shadow.global_position = global_position + Vector2(0, 0) 
	
func trigger_glitch_effect():
	var node := Global.post_effect_rect
	if node:
		node.visible = true
		var mat := node.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("glitch_amount", 1.0)
			await get_tree().create_timer(0.3).timeout
			if float(health_component.get_helth_value()) >= 0.3:
				node.visible = false
			else:
				mat.set_shader_parameter("glitch_amount", 0.2)
	
	# 🔴 Управляем цветом фона (code_bg_shader)
	if code_bg_shader:
		code_bg_shader.set_shader_parameter("hit_flash", 1.0)
		await get_tree().create_timer(0.8).timeout

		# Оставляем фон красным при < 30% HP
		var health_percent = float(health_component.get_helth_value())
		if health_percent < 0.3:
			code_bg_shader.set_shader_parameter("hit_flash", 1.0)
		else:
			code_bg_shader.set_shader_parameter("hit_flash", 0.0)
	

func clear_glitch_effect():
	if Global.post_effect_rect and Global.post_effect_rect.material:
		var shader_material := Global.post_effect_rect.material as ShaderMaterial
		if shader_material:
			shader_material.set_shader_parameter("glitch_amount", 0.0)
		code_bg_shader.set_shader_parameter("hit_flash", 0.0)


func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "hit":
		# Вернуть в idle или run, в зависимости от движения
		var direction = movement_vector()
		if direction.length() > 0:
			animated_sprite_2d.play("run")
		else:
			animated_sprite_2d.play("idle")
