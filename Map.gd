extends Node2D

var fp := Vector2()
var path: PoolVector2Array = []


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.pressed:
		match event.button_index:
			BUTTON_LEFT:
				if fp:
					path = $Navigation2D.get_simple_path(fp, get_local_mouse_position())
					fp = Vector2()
				else:
					path = []
					fp = get_local_mouse_position()
				update()
			BUTTON_RIGHT:
				pass


func _draw() -> void:
	if fp:
		draw_circle(fp, 16, Color.red)
	if path && path.size() >= 2:
		prints('path', path)
		draw_polyline(path, Color.red)
