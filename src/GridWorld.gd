extends Node2D


export var size := Vector2(16, 10)
export var cell_size := Vector2(64, 64)

var cells : PoolIntArray = []

func _ready():
	cells.resize(size.x * size.y)
	for i in cells.size():
		cells[i] = 0
		

func get_cell_valuev(v: Vector2) -> int:
	return get_cell_value(v.x, v.y)
	
func get_cell_value(x: int, y: int) -> int:
	assert(x >= 0 && x < size.x)
	assert(y >= 0 && y < size.y)
	return cells[x + y * size.x]
	

func set_cell_valuev(v: Vector2, value: int):
	set_cell_value(v.x, v.y, value)

func set_cell_value(x: int, y: int, value: int):
	assert(x >= 0 && x < size.x)
	assert(y >= 0 && y < size.y)
	cells[x + y * size.x] = value
	update()
	
func _draw():
	draw_rect(Rect2(Vector2.ZERO, size * cell_size), Color.blue, false)
	var drawn := 0
	var skipped := 0
	for i in cells.size():
		var v: int = cells[i]
		if v == 0:
			skipped += 1
			continue
		var x: int = i % int(size.x)
		var y: int = i / int(size.x)
		draw_rect(Rect2(Vector2(x, y) * cell_size, cell_size), Color.red)
		drawn += 1
	prints('drawn', drawn, 'skipped', skipped)
