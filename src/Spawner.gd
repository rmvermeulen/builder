tool
extends Node2D

const Enemy := preload("res://src/Enemy.gd")
const EnemyType = preload("res://src/Enemy.gd").TYPE

export (float, 0.1, 30) var spawn_interval := 10.0 setget set_spawn_interval
export (Vector2) var extents := Vector2(128, 128) setget set_extents
export (Array, Array, EnemyType) var spawn_parties := [] setget set_spawn_parties

var _active_timer: SceneTreeTimer = null


func _ready() -> void:
	visible = Engine.editor_hint
	if Engine.editor_hint:
		return
	start_interval()


func start_interval(elapsed: float = 0.0) -> void:
	if not is_inside_tree() || Engine.editor_hint:
		return
	if _active_timer:
		_active_timer.disconnect("timeout", self, "_on_interval_timer")
	_active_timer = get_tree().create_timer(max(0, spawn_interval - elapsed))
	Util.bind(_active_timer, "timeout", self, "_on_interval_timer")


func set_spawn_interval(value: float):
	if spawn_interval == value:
		return

	var was := spawn_interval
	spawn_interval = value

	if not _active_timer:
		start_interval()
	else:
		# create a new timer that goes of as if the new interval had been set at the start
		# or immediatley if the interval is already longer than that
		start_interval(was - _active_timer.time_left)


func set_extents(value: Vector2):
	extents = value
	update()


func set_spawn_parties(value: Array):
	var valid_types := []
	for party in value:
		var valid_party := []
		for item in party:
			if item >= 0 && item < EnemyType.size():
				valid_party.append(item)
		valid_types.append(valid_party)
	spawn_parties = valid_types
	update()


func _draw():
	draw_rect(Rect2(-extents, 2 * extents), Color.blue, false)


func _on_interval_timer():
	# remove ref to timer
	_active_timer = null

	# do the spawning
	prints('spawn interval')

	# restart the clock
	start_interval()
