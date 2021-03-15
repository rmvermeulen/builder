tool
extends Node2D

const OK := 1.0 / 50
const BAD := 1.0 / 20

var _last_delta := 0.0
var _cycle := 0.0


func _process(delta: float) -> void:
	_last_delta = delta
	_cycle += delta
	update()


func _draw() -> void:
	# find exact position
	var c := _cycle * 10
	var pos := Vector2(cos(c), sin(c * 2)) * Vector2(48, 8)

	# get color matching currect fps
	var color := Color.green
	if _last_delta > OK:
		color = Color.orange
	if _last_delta > BAD:
		color = Color.red
	color.a = 0.5

	draw_circle(pos, 12, color)
	draw_circle(-pos, 12, color)
