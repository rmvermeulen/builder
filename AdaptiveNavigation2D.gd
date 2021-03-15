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

	var results = []
	for outline in outlines:
		for c in collisions:
			var polygon = polygon_from_body(c.collider)
			for result in GoostGeometry2D.clip_polygons(outline, polygon):
				results.append(result)

	var navpoly := NavigationPolygon.new()
	for i in results.size():
		var child
		if i < get_child_count():
			child = get_child(i)
		else:
			child = NavigationPolygonInstance.new()
			add_child(child)
		navpoly.add_outline(results[i])
	navpoly.make_polygons_from_outlines()
	prints('outlines:', navpoly.get_outline_count())
	prints('polygons:', navpoly.get_polygon_count())
	poly.navpoly = navpoly
	update()


func _draw() -> void:
	var np := poly.navpoly
	var vs := np.get_vertices()
	for i in np.get_polygon_count():
		var ids :=  np.get_polygon(i)
		var p :=PoolVector2Array  ()
		for id in ids:
			p.append(vs[id])
		p.append(p[p.size() - 1])
		draw_polyline(p, Color.white, 1, true)


static func polygon_from_body(body: PhysicsBody2D) -> PoolVector2Array:
	var phs = Physics2DServer
	var rid: RID = body.get_rid()
	var s = phs.body_get_shape(rid, 0)
	var t = phs.body_get_shape_transform(rid, 0)
	# var m = phs.body_get_shape_metadata(rid, 0)
	var data = phs.shape_get_data(s)

	var polygon := PoolVector2Array()
	match [phs.shape_get_type(s), typeof(data)]:
		[phs.SHAPE_CIRCLE, TYPE_REAL]:
			prints("circle, radius =", data)
			polygon = GoostGeometry2D.circle(float(data))

		[phs.SHAPE_RECTANGLE, TYPE_VECTOR2]:
			prints("rect, extents =", data)
			var half: Vector2= data * 0.5
			polygon = PoolVector2Array([
				-half,
				Vector2(half.x, -half.y),
				half,
				Vector2(-half.x, half.y),
			])

		[_, TYPE_VECTOR2_ARRAY]:
			prints("convex/concave polygon, points =", data)
			polygon = data

		_:
			prints("unknown type", data, typeof(data))
	for i in polygon.size():
		polygon[i] = (body.transform * t).xform(polygon[i])
	return polygon
