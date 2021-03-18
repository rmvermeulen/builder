tool
extends Node2D

onready var grid_pos setget set_grid_pos

func _ready():
	set_grid_pos(Vector2(
		floor(position.x / 64),
		floor(position.y / 64)))
	
func set_grid_pos(value: Vector2):
	grid_pos = value
	position = grid_pos * 64

func _input(event):
	if event is InputEventKey && event.pressed:
		match event.scancode:
			KEY_SPACE:
				var p := get_parent()
				var c: int = p.get_cell_valuev(grid_pos)
				var v := 0 if c else 1
				p.set_cell_valuev(grid_pos, v)
				prints('set cell value', v, grid_pos)
			KEY_LEFT, KEY_A:
				self.grid_pos.x -= 1
			KEY_RIGHT, KEY_D:
				self.grid_pos.x += 1
			KEY_UP, KEY_W:
				self.grid_pos.y -= 1
			KEY_DOWN, KEY_S:
				self.grid_pos.y += 1

func _draw():
	draw_rect(Rect2(0, 0, 64, 64), Color.green, false)
