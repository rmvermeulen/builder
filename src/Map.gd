extends Node2D

const Block := preload("res://src/Block.tscn")
const Tower := preload("res://src/Obstacle.tscn")

var fp := Vector2()
var path: PoolVector2Array = []

onready var nav: Navigation2D = $Navigation2D


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
		draw_circle(fp, 16, Color.red)
	if path && path.size() >= 2:
		prints('path', path)
		draw_polyline(path, Color.red)
