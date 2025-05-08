extends Node

@export var end_screen_scene: PackedScene
@onready var player = %Player

var end_screen_instance: EndScreen = null  # <-- Объявляем один раз

func _ready():
	player.health_component.died.connect(on_died)

func on_died():
	end_screen_instance = end_screen_scene.instantiate() as EndScreen
	add_child(end_screen_instance)

func _on_room_trigger_body_entered(body):
	print("🚪 Кто-то вошёл в RoomTrigger:", body.name)

func _on_victory_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and end_screen_instance == null:
		print("🏆 Победа!")
		end_screen_instance = end_screen_scene.instantiate() as EndScreen
		add_child(end_screen_instance)
		end_screen_instance.change_to_victory()
