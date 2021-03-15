extends Control


func _ready():
	Util.bind(Game.state, "blueprint_changed", self)


func _on_blueprint_changed():
	var bp = Game.state.blueprint
	prints(name, "got bp from state", bp)
