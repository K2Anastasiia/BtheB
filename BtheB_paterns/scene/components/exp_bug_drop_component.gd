extends Node


@export var drop_percent = 0
@export var exp_bug_scene: PackedScene
@export var health_component: Node


func _ready():
	(health_component as HealthComponent).died.connect(on_died)
	
	
func on_died ():
	if randf() < drop_percent:
		return
	
	if exp_bug_scene == null:
		return
		
	if not owner is Node2D:
		return
		
	var spawn_pos = (owner as Node2D).global_position
	var back_layer = get_tree().get_first_node_in_group("back_layer")

	var exp_bug_instance = exp_bug_scene.instantiate() as Node2D
	back_layer.get_parent().add_child(exp_bug_instance)
	exp_bug_instance.global_position = spawn_pos
