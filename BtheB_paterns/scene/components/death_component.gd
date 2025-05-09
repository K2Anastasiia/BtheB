extends Node2D
class_name DeathComp

@onready var sprite_offset = $SpriteOffset
@onready var particles_2d: CPUParticles2D = $SpriteOffset/CPUParticles2D

func _ready():
	# ❌ Временно отключаем GPU-партиклы, чтобы избежать подвисаний
	#gpu_particles_2d.visible = false
	#gpu_particles_2d.emitting = false
	pass
