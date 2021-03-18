extends Node2D

const Enemy := preload("res://src/Enemy.gd")
const Block := preload("res://src/Block.tscn")
const Tower := preload("res://src/Obstacle.tscn")

var fp := Vector2()
var path: PoolVector2Array = []

onready var nav: Navigation2D = $Navigation2D

func _process(delta):
	update()
		
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
				var node = null
				match Game.state.blueprint:
					0:
						node = Block.instance()
					1:
						node = Tower.instance()
					_:
						prints("not implemented")
				if not node:
					return
				add_child(node)
				node.position = event.position
				nav.adapt()


func _draw() -> void:
	if fp:
		draw_circle(fp, 3, Color.red)
	if path && path.size() >= 2:
		draw_polyline(path, Color.red)
	var mp := get_local_mouse_position()
	match Game.state.blueprint:
		0:
			var extents = Vector2(24, 16)
			var rect := Rect2(mp - extents, 2 * extents)
			draw_rect(rect, Color.red, false)
		1:
			draw_arc(mp, 24, 0, TAU, 24, Color.red)
		_:
			pass
	for child in get_children():
		if not (child is Enemy):
			continue
		if child.path.size() < 2:
			continue
		draw_multiline(child.path, Color.yellow)
