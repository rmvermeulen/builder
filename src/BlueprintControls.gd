extends Control

onready var btn_block: Button = $Block
onready var btn_tower: Button = $Tower
onready var btn_house: Button = $House


func _ready():
	Util.bind(Game.state, "blueprint_changed", self)
	Util.bind(btn_block, "pressed", self, "_on_btn_block_pressed")
	Util.bind(btn_tower, "pressed", self, "_on_btn_tower_pressed")
	Util.bind(btn_house, "pressed", self, "_on_btn_house_pressed")
	update_buttons()


func _on_blueprint_changed():
	update_buttons()


func update_buttons():
	var bp: int = Game.state.blueprint
	btn_block.pressed = bp == 0
	btn_tower.pressed = bp == 1
	btn_house.pressed = bp == 2


func _on_btn_block_pressed():
	Game.state.blueprint = 0


func _on_btn_tower_pressed():
	Game.state.blueprint = 1


func _on_btn_house_pressed():
	Game.state.blueprint = 2
