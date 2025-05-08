extends CanvasLayer
class_name EndScreen

@onready var name_label = %NameLabel
@onready var panel_container = %PanelContainer
@onready var restart_button = %RestartButton
@onready var quit_button = %QuitButton
@onready var mouse_blocker = %MouseBlocker

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_blocker.focus_mode = Control.FOCUS_NONE

	panel_container.pivot_offset = panel_container.size / 2
	var tween = create_tween()
	tween.tween_property(panel_container, "scale", Vector2.ZERO, 0)
	tween.tween_property(panel_container, "scale", Vector2.ONE, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	await get_tree().process_frame
	restart_button.grab_focus()

	get_tree().paused = true
	print("🎬 EndScreen loaded")

func _process(_delta):
	var focus = get_viewport().gui_get_focus_owner()

	if Input.is_action_just_pressed("ui_accept"):
		if focus and focus.has_signal("pressed"):
			focus.emit_signal("pressed")

	if Input.is_action_just_pressed("ui_down"):
		var next = focus.find_next_valid_focus()
		if next:
			next.grab_focus()

	if Input.is_action_just_pressed("ui_up"):
		var prev = focus.find_prev_valid_focus()
		if prev:
			prev.grab_focus()

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://sheder/crt_wrapper.tscn")

func _on_quit_button_pressed():
	get_tree().quit()

func change_to_victory():
	name_label.text = "Victory"
	restart_button.text = "Play Again"
