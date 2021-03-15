extends Navigation2D

onready var poly: NavigationPolygonInstance = $NavigationPolygonInstance


func _ready() -> void:
	adapt()


func adapt() -> void:
	if not is_inside_tree():
		return
	# var cs := get_tree().current_scene

	var state := get_world_2d().direct_space_state

	var shape := RectangleShape2D.new()
	shape.extents = Vector2(512, 300)

	var query := Physics2DShapeQueryParameters.new()
	query.set_shape(shape)
	query.transform.origin = Vector2(512, 300)
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var collisions := state.intersect_shape(query)
	if collisions.empty():
		return

	var outlines := []
	for i in poly.navpoly.get_outline_count():
		outlines.append(poly.navpoly.get_outline(i))

	for outline in outlines:
		for c in collisions:
			var polygon = polygon_from_body(c.collider)
			prints(outline, polygon)


static func polygon_from_body(body: PhysicsBody2D) -> PoolVector2Array:
	var phs = Physics2DServer
	var rid: RID = body.get_rid()
	var s = phs.body_get_shape(rid, 0)
	var t = phs.body_get_shape_transform(rid, 0)
	var m = phs.body_get_shape_metadata(rid, 0)
	var data = phs.shape_get_data(s)
	match phs.shape_get_type(s):
		phs.SHAPE_CIRCLE:
			prints("circle, radius =", data)
			assert(typeof(data) == TYPE_REAL)
			return GoostGeometry2D.circle(float(data))
		phs.SHAPE_RECTANGLE:
			prints("rect, extents =", data)
			assert(typeof(data) == )
		phs.SHAPE_CONVEX_POLYGON:
			prints("convex, points =", data)
		phs.SHAPE_CONCAVE_POLYGON:
			prints("concave, points =", data)
		var type:
			prints("unknown type", type, data)
	prints('transform', t)
	if m:
		prints('meta', m)

	var result: PoolVector2Array = []
	return result
