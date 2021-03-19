extends Navigation2D

var obstacles := []

onready var navnode: NavigationPolygonInstance = $NavigationPolygonInstance
onready var original_navpoly: NavigationPolygon = navnode.navpoly

var _pos = null
var _path = []


func _input(event):
	if event is InputEventMouseButton && event.pressed:
		match event.button_index:
			BUTTON_LEFT:
				var p := GoostGeometry2D.regular_polygon(4, 32)
				for i in p.size():
					p[i] += event.position
				prints(p)
				obstacles.append(p)
				navnode.navpoly = cutout_obstacles()
				update()
			BUTTON_RIGHT:
				if _pos != null:
					_path = get_simple_path(_pos, event.position)
				_pos = event.position
				update()


func cutout_obstacles(margin := 10.0) -> NavigationPolygon:
	var vs := original_navpoly.get_vertices()
	var src_polys := []
	for i in original_navpoly.get_polygon_count():
		var poly := []
		for index in original_navpoly.get_polygon(i):
			poly.append(vs[index])
		src_polys.append(poly)

	var corrected_obstacles := PolyOffset2D.deflate_polygons(obstacles, margin)

	var polygons := PolyBoolean2D.clip_polygons(src_polys, corrected_obstacles)
	var set := []
	for p in polygons:
		for point in p:
			if point in set:
				continue
			set.append(point)

	var index_polygons := []
	for p in polygons:
		var ip := PoolIntArray([])
		for point in p:
			var index := set.find(point)
			assert(index >= 0)
			ip.append(index)
		index_polygons.append(ip)

	var np := NavigationPolygon.new()
	np.vertices = set
	for p in index_polygons:
		np.add_polygon(p)

	return np


func _draw() -> void:
	var nc := [
		Color(1, 0.5, 0.5, 0.5),
		Color(1, 1, 0.5, 0.5),
		Color(0.5, 1, 0.5, 0.5),
		Color(0.5, 1, 1, 0.5),
		Color(0.5, 0.5, 1, 0.5),
		Color(1, 0.5, 1, 0.5),
	]
	var np := navnode.navpoly
	var vertices := np.get_vertices()
	var pc := np.get_polygon_count()
	var cw := 0
	for i in pc:
		var p := []
		for index in np.get_polygon(i):
			p.append(vertices[index])
		cw += int(Geometry.is_polygon_clockwise(p))
		# draw_polygon(p, [nc[i % nc.size()]])
		draw_polyline(p, nc[i % nc.size()])
	prints('drawing %d nav-polygons clock-wise: %d/%d' % [pc, cw, pc])

	prints('drawing %d obstacles' % obstacles.size())
	for p in PolyOffset2D.deflate_polygons(obstacles, 10.0):
		# draw_polygon(p, [Color(1, 0, 0, 0.75)])
		draw_polyline(p, Color.red)

	if _pos != null:
		draw_circle(_pos, 8, Color.yellow)
	if _path.size() >= 2:
		prints('drawing path of length %d' % _path.size())
		draw_polyline(_path, Color.yellow)
