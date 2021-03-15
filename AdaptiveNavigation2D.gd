extends Navigation2D
const CIRCLE_SIDES := 6
const POLYGON_DRAW_STEP := 15
const POLYGON_DRAW_INTERVAL := 0.1
const GRID_CELL_SIZE := 64

onready var poly: NavigationPolygonInstance = $NavigationPolygonInstance

var drawn_polygons = 0

func _ready() -> void:
	var points := []
	for y in (600 / GRID_CELL_SIZE) + 1:
		for x in (1024 / GRID_CELL_SIZE) + 1:
			points.append(GRID_CELL_SIZE * Vector2(x, y))
	prints('points', points.size())
	var del = Geometry.triangulate_delaunay_2d(points)

	poly.navpoly.clear_polygons()
	poly.navpoly.clear_outlines()
	poly.navpoly.vertices = points
	for i in range(0, del.size(), 3):
		poly.navpoly.add_polygon([
			del[i],
			del[i + 1],
			del[i + 2],
		])
	update()

	# validate navpoly
	var vs := poly.navpoly.vertices
	for i in poly.navpoly.get_polygon_count():
		var pg = poly.navpoly.get_polygon(i)
		for p in pg:
			assert(p >= 0 && p < vs.size())

	yield (get_tree().create_timer(4.0), "timeout")
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

	var vertices :PoolVector2Array = poly.navpoly.get_vertices()
	prints('vertices', vertices.size())
	var polygons := []
	for i in poly.navpoly.get_polygon_count():
		var p := []
		for index in poly.navpoly.get_polygon(i):
			p.append(vertices[index])
		polygons.append(p)
	prints('nav polygons', polygons)

	var results = []
	for p in polygons:
		var current = [p]
		for c in collisions:
			var polygon = polygon_from_body(c.collider)
			var next = []
			for p2 in current:
				var clipped := GoostGeometry2D.clip_polygons(p2, polygon)

				var convexed = PolyDecomp2D.decompose_polygons(
					clipped, PolyDecomp2D.DECOMP_TRIANGLES_MONO)
				for r in convexed:
					next.append(r)
			current = next
		for c in current:
			results.append(c)
	prints('results', results.size())

	# create new vertices base set
	vertices = []
	for convex in results:
		for point in convex:
			if find_index(point, vertices) == -1:
				vertices.append(point)
	# create polygons from the base vertices
	polygons = []
	for convex in results:
		var polygon :PoolIntArray= []
		for i in convex.size():
			var vertex_index = find_index(convex[i], vertices)
			assert(vertex_index != -1, "failed to find %s in %s" % [convex[i], vertices])
			assert(vertex_index >= 0 && vertex_index < vertices.size())
			polygon.append(vertex_index)
		polygons.append(polygon)


	var navpoly := NavigationPolygon.new()
	navpoly.vertices = vertices
	for polygon in polygons:
		navpoly.add_polygon(polygon)
	prints('outlines:', navpoly.get_outline_count())
	prints('polygons:', navpoly.get_polygon_count())
	poly.navpoly = navpoly
	drawn_polygons = 0
	update()


func _draw() -> void:
	var cs := GoostEngine.get_color_constants().values()
	var np := poly.navpoly
	var vs := np.get_vertices()
	var total := np.get_polygon_count()
	drawn_polygons += POLYGON_DRAW_STEP
	var max_it := int(min(drawn_polygons, total))
	for i in max_it:
		var ids :=  np.get_polygon(i)
		var p: PoolVector2Array = []
		for id in ids:
			assert(id < vs.size())
			p.append(vs[id])
		p.append(p[p.size() - 1])
		var color = cs[i % cs.size()]
		color.a = 0.12
		draw_polygon(p, [color])
	if drawn_polygons < total:
		yield (get_tree().create_timer(POLYGON_DRAW_INTERVAL), "timeout")
		update()

static func find_index(value, list):
	for i in list.size():
		if list[i] == value:
			return i
	return -1

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
			# polygon = GoostGeometry2D.circle(float(data))
			polygon = GoostGeometry2D.regular_polygon(CIRCLE_SIDES, float(data))

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
