extends Navigation2D
const CIRCLE_SIDES := 8
const GRID_CELL_SIZE := 128

onready var nav_poly_node: NavigationPolygonInstance = $NavigationPolygonInstance

func _ready() -> void:
	var points := []
	for y in (600 / GRID_CELL_SIZE) + 2:
		for x in (1024 / GRID_CELL_SIZE) + 2:
			points.append(GRID_CELL_SIZE * Vector2(x, y))
	prints('points', points.size())
	var del = Geometry.triangulate_delaunay_2d(points)

	var np := nav_poly_node.navpoly
	np.clear_polygons()
	np.clear_outlines()
	np.vertices = points
	for i in range(0, del.size(), 3):
		np.add_polygon([
			del[i],
			del[i + 1],
			del[i + 2],
		])
	update()

	# validate navpoly
	var vs := np.vertices
	for i in np.get_polygon_count():
		var pg = np.get_polygon(i)
		for p in pg:
			assert(p >= 0 && p < vs.size())

	yield (get_tree().create_timer(1.0), "timeout")
	adapt()

func get_all_bodies() -> Array:
	var state := get_world_2d().direct_space_state

	var shape := RectangleShape2D.new()
	shape.extents = Vector2(512, 300)

	var query := Physics2DShapeQueryParameters.new()
	query.set_shape(shape)
	query.transform.origin = Vector2(512, 300)
	query.collide_with_bodies = true
	query.collide_with_areas = false

	var bodies = []
	for result in state.intersect_shape(query):
		bodies.append(result.collider)
	return bodies

func get_nav_polygons() -> Array:
	var np := nav_poly_node.navpoly
	var vertices: PoolVector2Array = np.get_vertices()
	prints('vertices', vertices.size())
	var polygons := []
	for i in np.get_polygon_count():
		var p := []
		for index in np.get_polygon(i):
			p.append(vertices[index])
		polygons.append(p)
	prints('nav polygons', polygons.size())
	return polygons

func clip_polygons(polygons:Array, clips:Array) -> Array:
	var results = []
	for p in polygons:
		var current = [p]
		for clip in clips:
			var clip_aabb = GoostGeometry2D.bounding_rect(clip)
			var next = []
			for poly in current:
				var aabb = GoostGeometry2D.bounding_rect(poly)
				if not aabb.intersects(clip_aabb):
					next.append(poly)
					continue
				var clipped := GoostGeometry2D.clip_polygons(poly, clip)
				var convexed = PolyDecomp2D.decompose_polygons(clipped, PolyDecomp2D.DECOMP_TRIANGLES_MONO)
				for r in convexed:
					next.append(r)
			current = next
		for c in current:
			results.append(c)
	prints('results', results.size())
	return results

func create_nav_poly(results:Array) -> NavigationPolygon:
	# create new vertices base set
	var vertices := []
	for convex in results:
		for point in convex:
			if find_index(point, vertices) == -1:
				vertices.append(point)
	# create polygons from the base vertices
	var polygons := []
	for convex in results:
		var polygon :PoolIntArray= []
		for i in convex.size():
			var vertex_index = find_index(convex[i], vertices)
			assert(vertex_index != -1, "failed to find %s in %s" % [convex[i], vertices])
			assert(vertex_index >= 0 && vertex_index < vertices.size())
			polygon.append(vertex_index)
		polygons.append(polygon)
	# add everything to a navigation polygon
	var navpoly := NavigationPolygon.new()
	navpoly.vertices = vertices
	for polygon in polygons:
		navpoly.add_polygon(polygon)

	return navpoly

func adapt() -> void:
	if not is_inside_tree():
		return

	var bodies := get_all_bodies()
	if bodies.empty():
		return

	var polygons = get_nav_polygons()

	var clips := []
	for body in bodies:
		clips.append(polygon_from_body(body))

	var results := clip_polygons(polygons, clips)

	var navpoly := create_nav_poly(results)

	prints('outlines:', navpoly.get_outline_count())
	prints('polygons:', navpoly.get_polygon_count())
	nav_poly_node.navpoly = navpoly
	update()


func _draw() -> void:
	var cs := GoostEngine.get_color_constants().values()
	var np := nav_poly_node.navpoly
	var vs := np.get_vertices()
	var total := np.get_polygon_count()
	for i in total:
		var ids :=  np.get_polygon(i)
		var p: PoolVector2Array = []
		for id in ids:
			assert(id < vs.size())
			p.append(vs[id])
		p.append(p[p.size() - 1])
		var color = cs[i % cs.size()]
		color.a = 0.12
		draw_polygon(p, [color])

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
			var extents: Vector2 = data
			polygon = PoolVector2Array([
				-extents,
				Vector2(extents.x, -extents.y),
				extents,
				Vector2(-extents.x, extents.y),
			])

		[_, TYPE_VECTOR2_ARRAY]:
			prints("convex/concave polygon, points =", data)
			polygon = data

		_:
			prints("unknown type", data, typeof(data))
	for i in polygon.size():
		polygon[i] = (body.transform * t).xform(polygon[i])
	return polygon
