extends Node
class_name HealthComponent

signal died
signal health_changed

@export var max_health: float  = 10
@export var damage_text_scene: PackedScene
var current_health: float


func _ready():
	current_health = max_health
	
	
func take_damage(damage):
	print("→ Урон:", damage)
	print("→ Было HP:", current_health)
	current_health = max(current_health - damage, 0)
	print("→ После урона HP:", current_health)
	health_changed.emit()
	Callable(check_death).call_deferred()

var is_dead: bool = false

func check_death():
	if is_dead:
		return
	print("Проверка смерти. HP:", current_health)
	if current_health <= 0:
		is_dead = true
		print("☠ Умер!")
		died.emit()

	
func get_helth_value() -> float:
	return current_health / max_health
	
		
func get_max_health() -> float:
	return max_health
