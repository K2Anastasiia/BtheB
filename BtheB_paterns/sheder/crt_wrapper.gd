extends Control

func _ready():
	
	Global.post_effect_rect = $PostEffectRect
	# Привязываем изображение с SubViewport к экрану
	$PostEffectRect.texture = $SubViewportContainer/GameViewport.get_texture()

	# Отключаем захват мыши PostEffectRect, чтобы клики проходили сквозь него
	$PostEffectRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
