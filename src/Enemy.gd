extends KinematicBody2D

enum TYPE { ALPHA, BETA, GAMMA }
export (TYPE) var type := TYPE.ALPHA

var path: PoolVector2Array = []
var vel := Vector2.ZERO
func _ready():
	find_path()
	while is_inside_tree():
		yield(get_tree().create_timer(1.0 + randf()), "timeout")
		find_path()
		
func _physics_process(delta):
	if path.empty():
		return
	var nearest = null
	if path.size() == 1:
		nearest = path[0]
	else:
		var points := []
		for i in path.size() - 1:
			points.append(
				Geometry.get_closest_point_to_segment_2d(position, path[i], path[i + 1])
			)
		# prefer segments at the end of the path, if the distance is equal
		points.invert()
		nearest = find_nearest(position, points)
	if not nearest:
		return
	var diff = nearest - position
	if diff.length() > 10:
		var step = diff.normalized()
		vel = step * 50
		vel = move_and_slide(vel)
	else:
		for i in path.size() - 1:
			path[i] = path[i + 1]
		path.resize(path.size() - 1)
	
func find_path():
	path = []
	var bases := get_tree().get_nodes_in_group("base")
	var points := []
	for base in bases:
		points.append(base.position)
	var nearest = find_nearest(position, points)
	if not nearest:
		return
	path = get_parent().nav.get_simple_path(position, nearest)
	
func _draw():
	draw_circle(Vector2.ZERO, 12, Color.red)
	
static func find_nearest(target: Vector2, points: PoolVector2Array) -> Vector2:
	var result = null
	var nd = 0.0
	for point in points:
		var d = target.distance_squared_to(point)
		if not result || d < nd:
			result = point
			nd = d
	return result
