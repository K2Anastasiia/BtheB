extends Area2D

func _ready():
	print("✅ VictoryTrigger готов")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("🚶 Игрок вошел в VictoryTrigger:", body.name)
