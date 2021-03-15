class_name State

signal blueprint_changed

enum Blueprint { BLOCK, TOWER, HOUSE }

var blueprint: int = Blueprint.BLOCK setget set_blueprint


func set_blueprint(value: int) -> void:
	var was := blueprint
	blueprint = wrapi(value, 0, Blueprint.size())
	if blueprint != was:
		emit_signal("blueprint_changed")
